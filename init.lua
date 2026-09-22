vim.g.mapleader = ' '
vim.loader.enable()
vim.pack.add({ { src = 'https://github.com/nvim-tree/nvim-web-devicons' } })
vim.pack.add({ { src = 'https://github.com/nvim-lua/plenary.nvim' } })

-- lsp plugins
require("extensions/blink")
require("extensions/mason")
require("extensions/lsp")

-- lsp extensions
require("extensions/lazydev")

-- file manager extensions
require("extensions/yazi")
-- require("extensions/zoxide")

-- search plugins
require("extensions/fzf")

-- movement plugins
require("extensions/hop")

-- git extensions
require("extensions/fugitive")

require("keymaps")
require("vimopts")
