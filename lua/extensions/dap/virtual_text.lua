local M = {}

function M.setup()
  -- vim.pack.add({ { src = "https://github.com/theHamsta/nvim-dap-virtual-text" } })
  vim.opt.runtimepath:prepend(vim.fn.stdpath("config") .. "/plugins_source/nvim-dap-virtual-text")

  require("nvim-dap-virtual-text").setup({
    virt_text_pos = "eol",
    enabled = true,
  })

end

return M
