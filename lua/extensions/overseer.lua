local M = {}

function M.setup()
  vim.pack.add({ { src = 'https://github.com/stevearc/overseer.nvim' } })
  local over = require("overseer")
  over.setup({
  })
end

M.setup()

return M
