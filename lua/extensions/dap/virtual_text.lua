local M = {}

function M.setup()
  -- vim.pack.add({ { src = "https://github.com/theHamsta/nvim-dap-virtual-text" } })
  vim.opt.runtimepath:prepend(vim.fn.stdpath("config") .. "/plugins_source/nvim-dap-virtual-text")

  require("nvim-dap-virtual-text").setup({
    virt_text_pos = "eol",
    enabled = true,
  })

  -- The plugin keeps the last exception message in module state and only
  -- drops it on "continue", so after a crash it was drawn on every later stop,
  -- even in new sessions. Drop it on each new stop (an exception stop sets it
  -- again right after) and whenever a session starts or ends.
  local dap = require("dap")
  local virtual_text = require("nvim-dap-virtual-text/virtual_text")
  local function reset_stop_reason()
    virtual_text._on_continue({})
  end
  local function reset_all()
    reset_stop_reason()
    virtual_text.clear_virtual_text()
    virtual_text.clear_last_frames()
  end
  dap.listeners.before.event_stopped.reset_stop_reason = reset_stop_reason
  dap.listeners.before.event_initialized.reset_stop_reason = reset_all
  dap.listeners.before.event_terminated.reset_stop_reason = reset_all
  dap.listeners.before.event_exited.reset_stop_reason = reset_all
  dap.listeners.after.disconnect.reset_stop_reason = reset_all
end

return M
