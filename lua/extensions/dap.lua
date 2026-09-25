local M = {}

function M.setup()
  vim.pack.add({
    { src = "https://github.com/mfussenegger/nvim-dap" },
    { src = "https://github.com/nvim-neotest/nvim-nio" },
  })

  local dap = require("dap")
  local overseer = require("overseer")

  -- Overseer is set up before nvim-dap is installed in init.lua.
  overseer.enable_dap()

  -- Python dap
  require("extensions/dap/python").setup(dap)

  -- CPP dap
  require("extensions/dap/cpp").setup(dap, overseer)

  -- DAP UI
  -- require("extensions/dap/dap_ui").setup()

  -- Virtual text
  require("extensions/dap/virtual_text").setup()

  -- Keymaps
  require("extensions/dap/keymaps").setup(dap)
end

M.setup()

return M
