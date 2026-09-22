local M = {}


function M.setup()
	vim.pack.add({ { src = 'https://github.com/mason-org/mason.nvim' } })
	vim.pack.add({ { src = 'https://github.com/mason-org/mason-lspconfig.nvim' } })
	require("mason").setup()
	require("mason-lspconfig").setup()
end

M.setup()

return M
