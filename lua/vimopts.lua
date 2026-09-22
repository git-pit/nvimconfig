local M = {}

local function tabline()
	local current = vim.api.nvim_tabpage_get_number(0)
	local count = vim.fn.tabpagenr('$')
	local parts = {}

	for i = 1, count do
		local highlight = i == current and '%#TabLineSel#' or '%#TabeLine#'
		local tab       = vim.api.nvim_list_tabpages()[i]
		local tab_name  = vim.t[tab].tabname
		local label
		if tab_name and tab_name ~= '' then
			label = tab_name
		else
			local win = vim.api.nvim_tabpage_get_win(tab)
			local buf = vim.api.nvim_win_get_buf(win)
			local file = vim.api.nvim_buf_get_name(buf)
			label = file == '' and '[No Name]' or vim.fn.fnamemodify(file, ':t')
		end

		table.insert(parts, string.format('%s%%%dT %d: %s ', highlight, i, i, label))
	end
	local result = table.concat(parts) .. '%#TabLineFill#%='
	if count > 1 then
		result = result .. '%999Xclose'
	end
	return result
end


local function set_tab_name(name)
	vim.t.tabname = name or ''
	vim.cmd('redrawtabline')
end

local function write_tab_names_to_session(session_file)
	if session_file == '' then
		return
	end

	local lines = {}
	for i, tab in ipairs(vim.api.nvim_list_tabpages()) do
		local name = vim.t[tab].tabname
		if name and name ~= '' then
			name = name:gsub("'", "''")
			table.insert(lines, string.format("call settabvar(%d, 'tabname', '%s')", i, name))
		end
	end

	if #lines > 0 then
		vim.fn.writefile(lines, session_file, 'a')
	end
end

local function save_session(file)
	file = file ~= '' and file or 'Session.vim'
	vim.cmd('mksession! ' .. vim.fn.fnameescape(file))
	write_tab_names_to_session(file)
	vim.notify('Saved session to ' .. file, vim.log.levels.INFO)
end

function M.setup()
	vim.opt.signcolumn = 'yes:2'
	vim.opt.tags = { './tags', './tags;', '~/.vim/all_tags' }
	vim.opt.relativenumber = true
	vim.opt.number = true
	vim.opt.tabstop = 2
	vim.opt.shiftwidth = 2
	vim.opt.expandtab = true
	vim.opt.wildmenu = true
	vim.opt.wildmode = { 'longest:full', 'full' }
	vim.opt.smartindent = true
	vim.opt.virtualedit = 'block'
	vim.opt.grepprg = [[rg --glob "!tags" --vimgrep]]
	vim.opt.path = '**'
	vim.opt.undofile = true
	vim.opt.undodir = vim.fn.stdpath('state') .. '/undo'
	vim.fn.mkdir(vim.fn.expand(vim.o.undodir), 'p')
	vim.opt.showtabline = 2
	vim.opt.tabline = '%!v:lua.MyTabLine()'
	vim.opt.fixendofline = false

	_G.MyTabLine = tabline
	_G.SetTabName = set_tab_name

	vim.api.nvim_create_user_command('SaveSession', function(opts)
		save_session(opts.args)
	end, { nargs = '?', complete = 'file' })
	vim.keymap.set('n', '<leader>cp', function()
		vim.fn.setreg('"', vim.fn.expand('%:p'))
		vim.notify('Copied: ' .. vim.fn.expand('%:p'), vim.log.levels.INFO)
	end)
	vim.keymap.set('n', '<space>nt', function()
		set_tab_name(vim.fn.input('Tab name: '))
	end)
	vim.keymap.set('n', '<space>tn', ':$tabe<cr>')
	vim.keymap.set('n', '<space>vr', ':vs | b #<cr>')
	vim.keymap.set('n', '<space>sr', ':sp | b #<cr>')
	vim.keymap.set({ 'o', 'x' }, 'if', ':normal! GVgg<cr>')
end

M.setup()

return M
