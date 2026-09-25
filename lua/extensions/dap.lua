local M = {}

function M.setup()
  vim.pack.add({
    { src = "https://github.com/mfussenegger/nvim-dap" },
    { src = "https://github.com/nvim-neotest/nvim-nio" },
    { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
  })

  local dap = require("dap")
  local overseer = require("overseer")

  -- Overseer is set up before nvim-dap is installed in init.lua.
  overseer.enable_dap()

  -- Python dap
  require("extensions/dap/python").setup(dap)

  -- CPP dap
  require("extensions/dap/cpp").setup(dap, overseer)

  require("extensions/dap/dap_ui").setup()

  require("nvim-dap-virtual-text").setup({
    virt_text_pos = "eol",
    enabled = true,
  })

  local arrow_steps = {
    ["<Right>"] = { dap.step_into, "Debug: step into" },
    ["<Down>"] = { dap.step_over, "Debug: step over" },
    ["<Up>"] = { dap.step_out, "Debug: step out" },
    ["<Left>"] = { dap.step_out, "Debug: step out" },
  }
  local previous_arrows

  local function enable_arrow_steps()
    if previous_arrows then return end
    previous_arrows = {}
    for key, mapping in pairs(arrow_steps) do
      previous_arrows[key] = vim.fn.maparg(key, "n", false, true)
      vim.keymap.set("n", key, mapping[1], { desc = mapping[2] })
    end
  end

  local function disable_arrow_steps()
    if not previous_arrows then return end
    for key, previous in pairs(previous_arrows) do
      vim.keymap.del("n", key)
      if type(previous) == "table" and next(previous) then
        vim.fn.mapset("n", false, previous)
      end
    end
    previous_arrows = nil
  end

  dap.listeners.after.event_initialized.dapui = function()
    enable_arrow_steps()
  end
  dap.listeners.before.event_terminated.dapui = function()
    disable_arrow_steps()
  end
  dap.listeners.before.event_exited.dapui = function()
    disable_arrow_steps()
  end
  dap.listeners.after.disconnect.dapui = function()
    disable_arrow_steps()
  end

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
