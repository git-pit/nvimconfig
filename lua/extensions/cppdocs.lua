local M = {}
local request = 0

-- Keep namespace qualifiers even though ':' is not normally in 'iskeyword'.
function M.symbol()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1
	for first, name, last in line:gmatch('()([%w_]+[:%w_]*)()') do
		if first <= col and col < last then
			return name:gsub(':+$', '')
		end
	end
	return vim.fn.expand('<cword>')
end

-- Resolve the declaration, including inherited methods, rather than searching
-- for an ambiguous bare name such as "clear".
function M.resolve(done)
	local fallback = M.symbol()
	local client = vim.lsp.get_clients({ bufnr = 0, name = 'clangd' })[1]
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local prefix = vim.api.nvim_get_current_line():sub(1, col):gsub('[%w_]+$', '')
	local function unresolved()
		if prefix:match('%.%s*$') or prefix:match('%->%s*$') then
			done(nil, 'Cannot resolve this member; wait for clangd or use :Cppman std::Class::method')
		else
			done(fallback)
		end
	end
	if not client then
		unresolved()
		return
	end
	local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
	local bufnr = vim.api.nvim_get_current_buf()
	local accepted = client:request('textDocument/symbolInfo', params, function(err, result)
		if not err then
			for _, info in ipairs(result or {}) do
				if info.name and info.name ~= '' then
					local scope = (info.containerName or ''):gsub(':+$', '')
					local name = (scope ~= '' and scope .. '::' or '') .. info.name
					-- libc++/libstdc++ inline namespaces and template arguments
					-- are absent from cppreference's manual names.
					name = name:gsub('std::__[%w_]+::', 'std::'):gsub('%b<>', '')
					done(name)
					return
				end
			end
		end
		unresolved()
	end, bufnr)
	if not accepted then unresolved() end
end

local function fetch(symbol, current_request)
	local width = math.max(1, math.min(100, vim.o.columns - 4))
	vim.notify('Loading C++ documentation: ' .. symbol)
	-- Piped cppman output is already rendered as plain text. Its on-demand
	-- cache makes subsequent lookups available offline, too.
	vim.system({ 'cppman', '--force-columns=' .. width, symbol }, {
		text = true,
		timeout = 30000,
	}, vim.schedule_wrap(function(result)
		if current_request ~= request then
			return
		end
		local output = vim.trim(result.stdout or '')
		-- cppman can report a download/render failure on stdout with exit 0.
		if result.code ~= 0 or output == '' or output:match('^error:') then
			local message = vim.trim(result.stderr or '')
			if message == '' then
				message = output ~= '' and output or 'No manual found (or lookup timed out)'
			end
			vim.notify('C++ documentation: ' .. message, vim.log.levels.WARN)
			return
		end

		local lines = vim.split(output, '\n', { plain = true })
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].filetype = 'man'
		vim.bo[buf].modifiable = false
		vim.bo[buf].bufhidden = 'wipe'
		local height = math.max(1, math.min(#lines, math.floor(vim.o.lines * 0.75), vim.o.lines - 4))
		local win = vim.api.nvim_open_win(buf, true, {
			relative = 'editor',
			row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
			col = math.max(0, math.floor((vim.o.columns - width) / 2)),
			width = width,
			height = height,
			style = 'minimal',
			border = 'rounded',
			title = ' C++: ' .. symbol .. ' ',
			title_pos = 'center',
		})
		vim.wo[win].wrap = false
		local function close()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end
		vim.keymap.set('n', 'q', close, { buffer = buf, silent = true, desc = 'Close C++ documentation' })
		vim.keymap.set('n', '<Esc>', close, { buffer = buf, silent = true })
	end))
end

function M.open(symbol)
	if vim.fn.executable('cppman') ~= 1 then
		vim.notify('C++ documentation requires cppman (brew install cppman)', vim.log.levels.ERROR)
		return
	end
	request = request + 1
	local current_request = request
	local function resolved(name, err)
		if current_request ~= request then return end
		if err then
			vim.notify('C++ documentation: ' .. err, vim.log.levels.WARN)
		elseif name and vim.trim(name) ~= '' then
			fetch(vim.trim(name), current_request)
		end
	end
	if symbol then
		resolved(symbol)
	else
		M.resolve(resolved)
	end
end

function M.setup()
	vim.api.nvim_create_user_command('Cppman', function(opts)
		if opts.args ~= '' then
			M.open(opts.args)
		else
			vim.ui.input({ prompt = 'C++ documentation: ', default = M.symbol() }, function(value)
				if value then M.open(value) end
			end)
		end
	end, { nargs = '?', desc = 'Read a C++ reference manual (e.g. :Cppman std::getline)' })
	vim.api.nvim_create_autocmd('FileType', {
		group = vim.api.nvim_create_augroup('CppDocumentation', { clear = true }),
		pattern = 'cpp',
		callback = function(event)
			vim.keymap.set({'n', 'v'}, 'gK', function() M.open() end, {
				buffer = event.buf,
				desc = 'C++ reference documentation',
			})
		end,
	})
end

return M
