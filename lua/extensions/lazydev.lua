local M = {}

function M.setup()
	vim.pack.add({ { src = 'https://github.com/folke/lazydev.nvim' } })
	require('lazydev').setup()
end

M.setup()

return M
