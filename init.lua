vim.g.mapleader = ' '
vim.loader.enable()
vim.pack.add({
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
})

-- auto-closing pairs (before blink, which wraps <CR>)
require('autopairs').setup()

-- Set up in order: zoxide needs fzf, dap needs overseer.
local extensions = {
  'treesitter',
  -- lsp
  'blink',
  'mason',
  'lsp',
  'lazydev',
  -- file manager
  'yazi',
  -- search
  'fzf',
  'zoxide',
  'fff',
  -- movement
  'hop',
  -- git
  'fugitive',
  'gitsigns',
  -- misc
  'overseer',
  'surround',
  'codecompanion',
  'dap',
  'textobjects',
  'grug-far',
}
for _, name in ipairs(extensions) do
  require('extensions.' .. name).setup()
end

require('keymaps').setup()
require('vimopts').setup()
