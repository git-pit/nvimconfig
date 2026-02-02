vim.pack.add {
	{ src = 'https://github.com/neovim/nvim-lspconfig' },
}
vim.pack.add {
	{ src = 'https://github.com/mason-org/mason.nvim' },
}
vim.pack.add {
	{ src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
}
vim.pack.add {
	{ src = 'https://github.com/folke/lazydev.nvim' },
}
vim.pack.add {
	{ src = 'https://github.com/hrsh7th/nvim-cmp' },
}
vim.pack.add {
	{ src = 'https://github.com/hrsh7th/cmp-nvim-lsp' },
}
vim.pack.add {
	{ src = 'https://github.com/willothy/flatten.nvim' },
}
vim.pack.add {
	{ src = 'https://github.com/nvim-telescope/telescope.nvim' },
}
vim.pack.add {
	{ src = 'https://github.com/nvim-telescope/telescope-fzf-native.nvim' },
}
vim.pack.add {
	{ src = 'https://github.com/nvim-tree/nvim-web-devicons' },
}
vim.pack.add {
	{ src = 'https://github.com/nvim-lua/plenary.nvim' },
}
-- Reserve a space in the gutter
-- This will avoid an annoying layout shift in the screen
vim.opt.signcolumn = 'yes'

-- This should be executed before you configure any language server
local lspconfig_defaults = require('lspconfig').util.default_config
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
	'force',
	lspconfig_defaults.capabilities,
	require('cmp_nvim_lsp').default_capabilities()
)
require('mason').setup()
require('mason-lspconfig').setup()
require('lazydev').setup()
require('flatten').setup({
	hooks = {
	},
	window = {
		open = 'tab',
	}
})


-- This is where you enable features that only work
-- if there is a language server active in the file
vim.api.nvim_create_autocmd('LspAttach', {
	desc = 'LSP actions',
	callback = function(event)
		local opts = { buffer = event.buf }

		vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
		vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
		vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
		vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
		vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
		vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
		vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
		vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
		vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
		vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
	end,
})

local cmp = require('cmp')

cmp.setup({
	sources = {
		{ name = 'nvim_lsp' },
	},
	preselect = 'item',
	completion = {
		autocomplete = false,
		completeopt = 'menu,menuone,noinsert',
	},
	mapping = cmp.mapping.preset.insert({
		['C-n'] = cmp.mapping.complete(),
	}),
})
