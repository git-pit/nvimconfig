local M = {}

function M.setup()
  vim.pack.add({ { src = 'https://github.com/mikavilpas/yazi.nvim' } })
  require("yazi").setup({
    floating_window_scaling_factor = 1,
    integrations = {
      grep_in_directory = "fzf-lua",
    },
  })
  vim.keymap.set("n", "<leader>tm", function()
    require("yazi").yazi()
  end)
end

M.setup()

return M
