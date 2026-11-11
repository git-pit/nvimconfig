local M = {}

function M.setup(dap)
  local arrow_steps = {
    ["<Right>"] = { dap.step_into, "Debug: step into" },
    ["<Down>"] = { dap.step_over, "Debug: step over" },
    ["<Up>"] = { dap.step_out, "Debug: step out" },
    ["<Left>"] = { dap.continue, "Debug: continue" },
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
  -- Keep the arrow maps while another debug session is still running.
  local function session_ended(session)
    for _, other in pairs(dap.sessions()) do
      if other ~= session then return end
    end
    disable_arrow_steps()
  end
  dap.listeners.before.event_terminated.arrow_key_maps = session_ended
  dap.listeners.before.event_exited.arrow_key_maps = session_ended
  dap.listeners.after.disconnect.arrow_key_maps = session_ended

  vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: step over" })
  vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: step into" })
  vim.keymap.set("n", "<S-F11>", dap.step_out, { desc = "Debug: step out" })
  -- Many terminals do not send <S-F11>.
  vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: step out" })

  vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: start/continue" })
  vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Debug: run last" })
  vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
  vim.keymap.set("n", "<leader>dC", function()
    local ok, condition = pcall(vim.fn.input, "Condition: ")
    if not ok or condition == "" then return end
    dap.toggle_breakpoint(condition)
  end, { desc = "Debug: toggle conditional breakpoint" })
  vim.keymap.set("n", "<leader>dR", dap.run_to_cursor, { desc = "Debug: run to cursor" })
  vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "Debug: toggle REPL" })
  vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug: terminate" })
  vim.keymap.set("n", "<leader>dP", dap.pause, { desc = "Debug: pause" })
  vim.keymap.set("n", "<leader>dB", dap.list_breakpoints, { desc = "Debug: list breakpoints" })

  -- Widgets
  local widgets = require("dap.ui.widgets")
  vim.keymap.set("n", "<leader>dh", widgets.hover, { desc = "Debug: hover value" })
  vim.keymap.set({ "n", "v" }, "<leader>dp", widgets.preview, { desc = "Debug: preview value" })
  vim.keymap.set("n", "<leader>ds", function()
    widgets.centered_float(widgets.scopes)
  end, { desc = "Debug: scopes float" })
  vim.keymap.set("n", "<leader>df", function()
    widgets.centered_float(widgets.frames)
  end, { desc = "Debug: frames float" })
end

return M
