local M = {}

function M.setup()
	vim.pack.add({ { src = 'https://github.com/tpope/vim-fugitive' } })
	vim.keymap.set('n', '<leader>gl', '<cmd>-tab Git log --oneline --decorate --graph<cr>')
	vim.keymap.set('n', '<leader>gL', '<cmd>-tab Git log<cr>')
	vim.keymap.set('n', '<leader>gg', '<cmd>-tab Git<cr>')
	vim.keymap.set('n', '<leader>gc', '<cmd>-tab Git commit<cr>')
	vim.keymap.set('n', '<leader>ga', '<cmd>-tab Git commit --ammend<cr>')
	vim.keymap.set('n', '<leader>gP', function()
		local branch = vim.fn['FugitiveHead']() or ''
		branch = vim.trim(branch)
		if branch == '' then
			vim.notify('Not on a branch (detached HEAD?)', vim.log.levels.WARN)
			return
		end
		vim.cmd('Git! push -u origin ' .. vim.fn.fnameescape(branch))
	end)
	vim.keymap.set('n', '<leader>gp', '<cmd>Git! pull<cr>')
	vim.keymap.set('n', '<leader>gdv', '<cmd>Gvdiffsplit!<cr>')
	vim.keymap.set('n', '<leader>gds', '<cmd>Gdiffsplit!<cr>')
	vim.keymap.set({'n', 'x'}, '<leader>gdt', ':diffget //2<cr>')
	vim.keymap.set({'n', 'x'}, '<leader>gdm', ':diffget //3<cr>')
end

M.setup()

return M
