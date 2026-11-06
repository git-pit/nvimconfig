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

local ns = vim.api.nvim_create_namespace('cppdocs')
local CODE_START, CODE_END = '@@cppdocs-code@@', '@@cppdocs-end@@'

-- cppman's groff source places version notes such as "[since C++11]" where
-- troff discards them, keeps cppreference's table of contents, and doesn't
-- distinguish example code from prose. Fix those up before rendering; code
-- blocks are bracketed with marker lines that layout() turns into ranges.
local function clean_source(source)
	local lines = vim.split(source, '\n', { plain = true })
	local out = {}
	local last_text, last_in_code
	local code, pending_code, requirements = false, false, false
	local skip = 0
	local function text(line)
		table.insert(out, line)
		last_text, last_in_code = #out, code
	end
	for i, line in ipairs(lines) do
		local req, arg = line:match('^%.(%a+)%s*(.-)%s*$')
		if skip > 0 then
			if req == 'RS' then
				skip = skip + 1
			elseif req == 'RE' then
				skip = skip - 1
			end
		elseif req == 'RS' and (lines[i + 1] or ''):match('^%d[%d.]* %S') then
			skip = 1
		elseif req then
			local note = arg:match('^%[(.-)%]$')
			if note then
				if last_text then
					out[last_text] = out[last_text] .. (last_in_code and '  // ' .. note or ' (' .. note .. ')')
				end
				arg = ''
			end
			if req == 'IP' then
				-- The trailing space keeps a tag exactly as wide as the indent
				-- from running into its description.
				arg = arg:gsub(' %(3%)', ''):gsub('^(".*)"$', '%1\\ "')
			end
			if req == 'fi' and code then
				table.insert(out, CODE_END)
				code = false
			end
			table.insert(out, arg ~= '' and '.' .. req .. ' ' .. arg or '.' .. req)
			if req == 'nf' and pending_code then
				table.insert(out, CODE_START)
				code = true
			end
			pending_code = req == 'in' and arg == '+2n'
			requirements = false
		elseif not code and line:match('^#include%s*<.->$') then
			vim.list_extend(out, { '.in +2n', '.nf', CODE_START })
			code = true
			text(line)
			vim.list_extend(out, { CODE_END, '.fi', '.in' })
			code = false
		elseif line == 'Type requirements' then
			vim.list_extend(out, { '.sp' })
			text(line .. ':')
			table.insert(out, '.br')
			requirements = true
		else
			if requirements and line:match('^%-') then
				table.insert(out, '.br')
			end
			text(line)
		end
	end
	return table.concat(out, '\n')
end

-- Turn rendered text into buffer lines: drop the page header/footer, the
-- breadcrumb, table of contents and wiki navigation, squeeze blank runs and
-- collect the code-block markers' line ranges (0-based, end-exclusive).
local function layout(text)
	local lines, code, start = {}, {}, nil
	for _, line in ipairs(vim.split(text, '\n', { plain = true })) do
		line = line:gsub('%s+$', '')
		local trimmed = vim.trim(line)
		if trimmed == 'Categories:' or trimmed == 'Navigation' then
			break
		elseif trimmed == CODE_START then
			-- Separate consecutive declarations, e.g. a function's overloads.
			if #code > 0 and code[#code][2] == #lines then
				table.insert(lines, '')
			end
			start = #lines
		elseif trimmed == CODE_END then
			if start and #lines > start then
				table.insert(code, { start, #lines })
			end
			start = nil
		elseif line:find('C++ Programmer', 1, true)
			or trimmed:match('^< cpp%f[%W]')
			or trimmed:match('^1 %a[%w ]* 2 %a') then
			-- Page header, breadcrumb and table of contents.
		elseif line == '' then
			if #lines > 0 and lines[#lines] ~= '' then
				table.insert(lines, '')
			end
		else
			table.insert(lines, line)
		end
	end
	while lines[#lines] == '' or (lines[#lines] or ''):match('^%S.*%(3%)$') do
		table.remove(lines)
	end
	return lines, code
end

local function highlight(buf, lines, code)
	local in_code = {}
	for _, range in ipairs(code) do
		for row = range[1], range[2] - 1 do in_code[row] = true end
	end
	for row, line in ipairs(lines) do
		if not in_code[row - 1] then
			-- Version notes like "[since C++11]" and captions like
			-- "(public member function)".
			for first, last in line:gmatch('()[%[(][^%[%]()]-C%+%+%d%d%a?[%])]()') do
				vim.api.nvim_buf_set_extmark(buf, ns, row - 1, first - 1, { end_col = last - 1, hl_group = 'Comment' })
			end
			local first, last = line:match('^%s*()%(.*%)()$')
			if first then
				vim.api.nvim_buf_set_extmark(buf, ns, row - 1, first - 1, { end_col = last - 1, hl_group = 'Comment' })
			end
		end
	end
	local ok, query = pcall(vim.treesitter.query.get, 'cpp', 'highlights')
	if not ok or not query then return end
	for _, range in ipairs(code) do
		local source = table.concat(lines, '\n', range[1] + 1, range[2])
		local parsed, parser = pcall(vim.treesitter.get_string_parser, source, 'cpp')
		if parsed then
			local root = parser:parse()[1]:root()
			for id, node, metadata in query:iter_captures(root, source) do
				local name = query.captures[id]
				if not name:match('^_') and name ~= 'spell' and name ~= 'nospell' and name ~= 'conceal' then
					local sr, sc, er, ec = node:range()
					vim.api.nvim_buf_set_extmark(buf, ns, range[1] + sr, sc, {
						end_row = range[1] + er,
						end_col = ec,
						hl_group = '@' .. name .. '.cpp',
						priority = tonumber(metadata.priority or (metadata[id] or {}).priority) or vim.hl.priorities.treesitter,
					})
				end
			end
		end
	end
end

local function show(symbol, lines, code, width)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = 'man'
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = 'wipe'
	highlight(buf, lines, code)
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
end

-- The full page name (e.g. "std::vector<T,Allocator>::push_back") opens the
-- NAME section and names cppman's cache file.
local function cached_page(output)
	local name = output:match('\nNAME\n(.-)%s+%-%s')
	if not name or name:find('\n%s*\n') then return end
	name = vim.trim(name:gsub('%s+', ' ')):gsub('/', '_')
	local cache = (vim.env.XDG_CACHE_HOME or vim.fs.joinpath(vim.env.HOME, '.cache')) .. '/cppman'
	for _, source in ipairs({ 'cppreference.com', 'cplusplus.com' }) do
		local path = vim.fs.joinpath(cache, source, name .. '.3.gz')
		if vim.uv.fs_stat(path) then return path end
	end
end

-- Render cppman's cached groff source ourselves: left-aligned without
-- hyphenation, at the window's width and with the clutter removed.
local function render(path, width, done)
	vim.system({ 'gzip', '-dc', path }, { text = true }, function(source)
		if source.code ~= 0 then return done() end
		local ok = pcall(vim.system, {
			'groff', '-t', '-man', '-Tascii', '-P', '-cbou', '-rcR=1', '-rHY=0', '-dAD=l',
			'-rLL=' .. width .. 'n', '-rLT=' .. width .. 'n',
		}, { text = true, stdin = clean_source(source.stdout) }, function(result)
			done(result.code == 0 and result.stdout ~= '' and result.stdout or nil)
		end)
		if not ok then done() end
	end)
end

local function fetch(symbol, current_request)
	local width = math.max(1, math.min(100, vim.o.columns - 4))
	vim.notify('Loading C++ documentation: ' .. symbol)
	-- cppman resolves the name and caches the page (so later lookups work
	-- offline); its piped plain-text output is the fallback rendering.
	vim.system({ 'cppman', '--force-columns=' .. width, symbol }, {
		text = true,
		timeout = 30000,
		-- A UTF-8 locale makes groff print typographic hyphens and quotes,
		-- which corrupt code samples.
		env = { LANG = 'C', LC_ALL = 'C' },
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

		local path = cached_page(output)
		if not path then
			show(symbol, (layout(output)), {}, width)
			return
		end
		render(path, width - 2, vim.schedule_wrap(function(rendered)
			if current_request ~= request then return end
			if rendered then
				local lines, code = layout(rendered)
				show(symbol, lines, code, width)
			else
				show(symbol, (layout(output)), {}, width)
			end
		end))
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
