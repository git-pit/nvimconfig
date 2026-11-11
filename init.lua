vim.g.mapleader = ' '
vim.loader.enable()
vim.pack.add({ { src = 'https://github.com/nvim-tree/nvim-web-devicons' } })
vim.pack.add({ { src = 'https://github.com/nvim-lua/plenary.nvim' } })
vim.pack.add({ { src = 'https://github.com/nvim-treesitter/nvim-treesitter' } })

-- auto-closing pairs (before blink, which wraps <CR>)
require("autopairs").setup()

-- lsp plugins
require("extensions/blink")
require("extensions/mason")
require("extensions/lsp")

-- lsp extensions
require("extensions/lazydev")

-- file manager extensions
require("extensions/yazi")

-- search plugins
require("extensions/fzf")
require("extensions/zoxide")
require("extensions/fff")

-- movement plugins
require("extensions/hop")

-- git extensions
require("extensions/fugitive")
require("extensions/gitsigns")

-- misc
require("extensions/overseer")
require("extensions/surround")
require("extensions/codecompanion")
require("extensions/dap")
require("extensions/textobjects")
require("extensions/grug-far")

require("keymaps")
require("vimopts")
