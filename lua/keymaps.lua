local M = {}

function M.setup()
	vim.keymap.set({ 'n', 'v' }, '<leader>nh', '<cmd>noh <cr>')
	vim.keymap.set({ 'n' }, '<leader>qo', '<cmd>copen | wincmd L <cr>')
	vim.keymap.set({ 'n' }, '<leader>qO', '<cmd>copen | wincmd T | tabmove - <cr>')
	vim.keymap.set({ 'n' }, '<leader>qc', '<cmd>ccl <cr>')
	vim.keymap.set('n', '<leader>tt', '<cmd>-tab term<cr>')
	vim.keymap.set('n', '<leader>vt', '<cmd>vs | term<cr>')
	vim.keymap.set({ 'n', 'v', 't' }, '<C-w>q', '<cmd>bd!<cr>')
	vim.keymap.set({ 'n', 'v', 't' }, '<C-w><C-q>', '<cmd>bd!<cr>')
	vim.keymap.set('n', '<leader>nb', ':file ')
	vim.keymap.set('n', '<leader>ts', '<cmd>set spell!<cr>')
	vim.keymap.set('n', '<leader>tl', '<cmd>set rnu! | set nu! | Gitsigns toggle_signs <cr>')
	vim.keymap.set('n', '<leader>cd', '<cmd>lcd %:h<cr>')

	-- The ultimate 1-1 Vim Terminal <C-w> parser for Neovim
	vim.keymap.set('t', '<C-w>', function()
		local count = 0
		local char = vim.fn.getchar()

		-- 1. Dynamically parse numerical counts (e.g., <C-w>5>)
		while type(char) == 'number' and char >= 48 and char <= 57 do
			count = count * 10 + (char - 48)
			char = vim.fn.getchar()
		end

		-- Cancel silently and stay in Terminal mode if the user presses <Esc>
		if char == 27 then return end

		local c = type(char) == 'number' and vim.fn.nr2char(char) or char

		-- 2. Normalize Control-characters (e.g., <C-w><C-w> becomes <C-w>w)
		if type(char) == 'number' and char >= 1 and char <= 26 then
			c = string.char(char + 96)
		end

		local cnt_str = count > 0 and tostring(count) or ""

		-- 3. Handle sending literal <C-w> to the terminal (e.g., <C-w>. or <C-w>3.)
		if c == '.' then
			vim.api.nvim_chan_send(vim.b.terminal_job_id, string.rep("\x17", count > 0 and count or 1))
			return
		end

		-- 4. Handle completely dropping to Normal mode (<C-w>N)
		if c == 'N' then
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[<C-\><C-n>]], true, true, true), 'n',
				false)
			return
		end

		-- 5. Handle pasting from a register natively into the shell (<C-w>")
		if c == '"' then
			local reg_char = vim.fn.getchar()
			if reg_char == 27 then return end -- Cancel on <Esc>
			local text = vim.fn.getreg(vim.fn.nr2char(reg_char))
			vim.api.nvim_chan_send(vim.b.terminal_job_id, text)
			return
		end

		-- 6. Handle tab navigation (e.g., <C-w>gt, <C-w>2gT)
		if c == 'g' then
			local next_char = vim.fn.getchar()
			if next_char == 27 then return end
			local nc = type(next_char) == 'number' and vim.fn.nr2char(next_char) or next_char
			if nc == 't' then
				vim.cmd(cnt_str .. 'tabnext')
			elseif nc == 'T' then
				vim.cmd(cnt_str .. 'tabprevious')
			end
			return
		end

		-- 7. Handle opening the command line natively (<C-w>:)
		if c == ':' then
			vim.api.nvim_feedkeys(':', 'n', false)
			return
		end

		-- 8. Execute arbitrary standard window commands with counts natively
		pcall(function()
			vim.cmd(cnt_str .. 'wincmd ' .. c)
		end)
	end, { noremap = true, silent = true, desc = 'Exact 1-1 Vim Terminal <C-w>' })
end

M.setup()

return M
