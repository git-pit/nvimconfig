local M = {}
vim.pack.add({ { src = 'https://github.com/neovim/nvim-lspconfig' } })

require("extensions/mason")

function M.setup()
	local lspconfig_defaults = require("lspconfig").util.default_config
	require("mason-lspconfig").setup({
		config = function(_, opts)
			local lspconfig = require("lspconfig")
			for server, config in pairs(opts.servers) do
				-- if server ~= 'jdtls' then
				config.capabilites = require('blink.cmp').get_lsp_capabilites(config.capabilities)
				lspconfig[server].setup(config)
			end
		end
	})

	vim.api.nvim_create_autocmd("LspAttach", {
		desc = 'LSP actions',
		callback = function(event)
			local opts = { buffer = event.buf }

			vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, opts)
			vim.keymap.set('n', '<F4>', vim.lsp.buf.code_action, opts)
			vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
			vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
			vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
			vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
			vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, opts)
			vim.keymap.set({'n', 'x'}, '<F3>', function()
				vim.lsp.buf.format({async=true})
			end, opts)
		end,
	})
end

M.setup()

return M
