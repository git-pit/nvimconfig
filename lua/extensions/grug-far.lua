local M = {}

function M.setup()
  vim.pack.add({ { src = 'https://github.com/MagicDuck/grug-far.nvim' } })
  require("grug-far").setup({

  })
end

return M
