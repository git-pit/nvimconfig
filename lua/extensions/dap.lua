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

  -- Restart by terminating and launching a fresh adapter. An adapter-side
  -- "restart" request (lldb-dap) keeps the old session, so its exception
  -- diagnostics stay on screen and the relaunched program may never run.
  local function force_fresh_restart(session)
    if session.capabilities then
      session.capabilities.supportsRestartRequest = false
    end
  end
  dap.listeners.after.initialize.fresh_restart = force_fresh_restart
  dap.listeners.after.event_capabilities.fresh_restart = force_fresh_restart

  -- Python dap
  require("extensions/dap/python").setup(dap)

  -- CPP dap
  require("extensions/dap/cpp").setup(dap, overseer)

  -- DAP UI
  require("extensions/dap/dap_ui").setup(dap)

  -- Virtual text
  require("extensions/dap/virtual_text").setup()

  -- Keymaps
  require("extensions/dap/keymaps").setup(dap)
  require("extensions/dap/assembly").setup(dap)
end

M.setup()

return M
