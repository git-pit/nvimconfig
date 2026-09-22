local M = {}

function M.setup()
  vim.pack.add({ { src = 'https://github.com/smoka7/hop.nvim' } })
  require("hop").setup({
    multi_windows = true
  })
  vim.keymap.set({ 'n', 'x', 'o' }, 'f', '<cmd>HopChar1<cr>')
end

M.setup()

return M
