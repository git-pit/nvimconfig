local M = {}

function M.setup(dap)
  vim.pack.add({ { src = "https://github.com/rcarriga/nvim-dap-ui" } })
  local dapui = require("dapui")
  require("extensions/dap/dapui_edit").setup()
  dapui.setup({
    wrap = false,
    icons = { expanded = "", collapsed = "", current_frame = "" },
    -- Only bind actions supported by each panel.
    mappings = {
      expand = {},
      open = {},
      remove = {},
      edit = {},
      repl = {},
      toggle = {},
      watch = {},
    },
    element_mappings = {
      scopes = {
        expand = { "<CR>", "<2-LeftMouse>" },
        edit = "e",
        repl = "r",
        watch = "w",
      },
      watches = {
        expand = { "<CR>", "<2-LeftMouse>" },
        edit = "e",
        remove = "d",
        repl = "r",
      },
      stacks = { open = { "<CR>", "o" }, toggle = "t" },
      breakpoints = { open = { "<CR>", "o" }, remove = "d", toggle = "t" },
      hover = { edit = "e" },
    },
    expand_lines = true,
    force_buffers = true,
    layouts = {
      {
        elements = {
          { id = "scopes",      size = 0.35 },
          { id = "watches",     size = 0.30 },
          { id = "stacks",      size = 0.20 },
          { id = "breakpoints", size = 0.15 },
        },
        position = "right",
        size = 67,
      },
      {
        elements = { "console" },
        position = "bottom",
        size = 10,
      },
    },
    floating = { border = "single", mappings = { close = { "q", "<Esc>" } } },
    controls = {
      enabled = false,
      element = "console",
      icons = {
        pause = "",
        play = "",
        step_into = "",
        step_over = "",
        step_out = "",
        step_back = "",
        run_last = "",
        terminate = "",
      },
    },
    render = { indent = 1, max_value_lines = 100 },
  })

  dap.listeners.after.event_initialized.dapui = function()
    dapui.close()
  end
  -- dap.listeners.before.event_terminated.dapui = function()
  -- end
  -- dap.listeners.before.event_exited.dapui = function()
  -- end
  -- dap.listeners.after.disconnect.dapui = function()
  -- end

  -- Dap UI keymaps
  vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: toggle panels" })
  vim.keymap.set("n", "<leader>di", function()
    local buf = dapui.elements.console.buffer()
    if vim.bo[buf].buftype ~= "terminal" then
      vim.notify("No active debug terminal", vim.log.levels.INFO)
      return
    end
    local win = vim.fn.bufwinid(buf)
    if win == -1 then
      dapui.open()
      win = vim.fn.bufwinid(buf)
    end
    if win ~= -1 then
      vim.api.nvim_set_current_win(win)
      vim.cmd.startinsert()
    end
  end, { desc = "Debug: focus program terminal" })
  vim.keymap.set({ "n", "v" }, "<leader>de", dapui.eval, { desc = "Debug: evaluate expression" })
  vim.keymap.set({ "n", "v" }, "<leader>dw", function()
    dapui.elements.watches.add(vim.fn.expand("<cword>"))
  end, { desc = "Debug: watch word" })
end

return M
