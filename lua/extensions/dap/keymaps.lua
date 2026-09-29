local M = {}

function M.setup(dap)
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

  dap.listeners.after.event_initialized.arrow_key_maps = function()
    enable_arrow_steps()
  end
  dap.listeners.before.event_terminated.arrow_key_maps = function()
    disable_arrow_steps()
  end
  dap.listeners.before.event_exited.arrow_key_maps = function()
    disable_arrow_steps()
  end
  dap.listeners.after.disconnect.arrow_key_maps = function()
    disable_arrow_steps()
  end

  vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: step over" })
  vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: step into" })
  vim.keymap.set("n", "<S-F11>", dap.step_out, { desc = "Debug: step out" })

  vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: start/continue" })
  vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Debug: run last" })
  vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
  vim.keymap.set("n", "<leader>dC", function()
    dap.toggle_breakpoint(vim.fn.input("Condition: "))
  end, { desc = "Debug: toggle conditional breakpoint" })
  vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Debug: open REPL" })
  vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug: terminate" })
  vim.keymap.set("n", "<leader>dP", dap.pause, { desc = "Debug: pause" })

  -- Widgets
  local widgets = require('dap.ui.widgets')
  local floating_widget_size = nil
  vim.keymap.set("n", "<leader>dh", function()
    widgets.hover()
  end)
  vim.keymap.set({ 'n', 'v' }, '<Leader>dp', function()
    require('dap.ui.widgets').preview()
  end)

  vim.keymap.set("n", "<leader>ds",
    function()
      widgets.centered_float(widgets.scopes, floating_widget_size)
    end)

  vim.keymap.set("n", "<leader>dB",
    function()
      dap.list_breakpoints()
    end)

  vim.keymap.set("n", "<leader>df",
    function()
      widgets.centered_float(widgets.frames, floating_widget_size)
    end)
end

return M
