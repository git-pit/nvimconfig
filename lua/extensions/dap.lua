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

  -- require("extensions/dap/dap_ui").setup()

  -- Virtual text
  require("extensions/dap/virtual_text").setup()

  vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: start/continue" })
  vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: step over" })
  vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: step into" })
  vim.keymap.set("n", "<S-F11>", dap.step_out, { desc = "Debug: step out" })
  vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
  vim.keymap.set("n", "<leader>dC", function()
    dap.toggle_breakpoint(vim.fn.input("Condition: "))
  end, { desc = "Debug: toggle conditional breakpoint" })
  vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Debug: open REPL" })
  vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug: terminate" })
end

M.setup()

return M
