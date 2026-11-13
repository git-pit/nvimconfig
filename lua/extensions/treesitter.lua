local M = {}

local parsers = { 'c', 'cpp', 'lua', 'python' }

function M.setup()
  vim.pack.add({ { src = 'https://github.com/nvim-treesitter/nvim-treesitter' } })
  -- Does nothing for parsers that are already installed.
  require('nvim-treesitter').install(parsers)

  -- nvim-treesitter no longer enables highlighting itself.
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('TreesitterHighlight', { clear = true }),
    callback = function(event)
      -- Errors for filetypes without a parser, which then keep regex syntax.
      pcall(vim.treesitter.start, event.buf)
    end,
  })
end

return M
