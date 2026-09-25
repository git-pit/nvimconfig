local M = {}

local function project_dir()
  local file = vim.api.nvim_buf_get_name(0)
  local start = file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
  local makefile = vim.fs.find("Makefile", { path = start, upward = true })[1]
  return makefile and vim.fs.dirname(makefile) or vim.fn.getcwd()
end

local function executable()
  local dir = project_dir()
  if vim.fn.filereadable(dir .. "/Makefile") == 1 then
    local result = vim.system({ "make", "-B", "-n" }, { cwd = dir, text = true }):wait()
    if result.code == 0 then
      local candidates = {}
      for output in (result.stdout or ""):gmatch("%-o%s+([^%s]+)") do
        output = output:gsub("^[\"']", ""):gsub("[\"']$", "")
        if not output:match("%.o$") and not output:match("%.a$")
            and not output:match("%.so$") and not output:match("%.dylib$") then
          local path = vim.fs.normalize(output:sub(1, 1) == "/" and output or dir .. "/" .. output)
          candidates[path] = true
        end
      end
      local paths = vim.tbl_keys(candidates)
      if #paths == 1 then
        return paths[1]
      end
    end
  end
  return vim.fn.input("Executable: ", dir .. "/", "file")
end

function M.setup()
  vim.pack.add({
    { src = "https://github.com/mfussenegger/nvim-dap" },
    { src = "https://github.com/nvim-neotest/nvim-nio" },
    { src = "https://github.com/rcarriga/nvim-dap-ui" },
    { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
  })

  local dap = require("dap")
  local overseer = require("overseer")

  -- Overseer is set up before nvim-dap is installed in init.lua.
  overseer.enable_dap()

  -- Python dap
  require("extensions/dap/python").setup(dap)

  -- CPP dap
  overseer.register_template({
    name = "C++: make",
    builder = function()
      return {
        cmd = { "make" },
        cwd = project_dir(),
        components = { "default" },
      }
    end,
  })

  local lldb_dap = ""
  if vim.fn.has("mac") == 1 and vim.fn.executable("brew") == 1 then
    local llvm = vim.system({ "brew", "--prefix", "llvm" }, { text = true }):wait()
    if llvm.code == 0 then
      local candidate = vim.fn.trim(llvm.stdout) .. "/bin/lldb-dap"
      if vim.fn.executable(candidate) == 1 then
        lldb_dap = candidate
      end
    end
  end
  if lldb_dap == "" then
    lldb_dap = vim.fn.exepath("lldb-dap")
  end
  if lldb_dap == "" and vim.fn.has("mac") == 1 then
    lldb_dap = vim.fn.trim(vim.fn.system({ "xcrun", "--find", "lldb-dap" }))
  end
  if lldb_dap == "" or vim.fn.executable(lldb_dap) == 0 then
    vim.notify("C++ debugging requires lldb-dap", vim.log.levels.WARN)
    return
  end

  dap.adapters.lldb = {
    type = "executable",
    command = lldb_dap,
    name = "lldb",
  }
  dap.adapters["lldb-dap"] = dap.adapters.lldb
  dap.listeners.on_config.dapui_console = function(config)
    if config.request == "launch" and (config.type == "lldb" or config.type == "lldb-dap")
        and config.console == nil then
      config.console = "integratedTerminal"
    end
    return config
  end

  local fallback = {
    {
      name = "Build with make and debug",
      type = "lldb",
      request = "launch",
      preLaunchTask = "C++: make",
      program = executable,
      cwd = project_dir,
      stopOnEntry = false,
    },
    {
      name = "Build with make and debug with args",
      type = "lldb",
      request = "launch",
      preLaunchTask = "C++: make",
      program = executable,
      cwd = project_dir,
      args = function() return vim.split(vim.fn.input("Args: "), ' ', { trimempty = true }) end,
      stopOnEntry = false,
    },
    {
      name = "Debug executable (no build)",
      type = "lldb",
      request = "launch",
      program = executable,
      cwd = project_dir,
      stopOnEntry = false,
    },
  }
  dap.providers.configs["cpp.make_fallback"] = function(bufnr)
    local filetype = vim.bo[bufnr].filetype
    if filetype ~= "c" and filetype ~= "cpp" then
      return {}
    end
    local ok, project_configs = pcall(require("dap.ext.vscode").getconfigs)
    if ok and #project_configs > 0 then
      return {}
    end
    if vim.fn.filereadable(project_dir() .. "/Makefile") == 0 then
      return { fallback[2] }
    end
    return fallback
  end

  local dapui = require("dapui")
  require("extensions.dapui_edit").setup()
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
  vim.keymap.set("n", "<leader>dw", function()
    dapui.elements.watches.add(vim.fn.expand("<cword>"))
  end, { desc = "Debug: watch word" })
  vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Debug: open REPL" })
  vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug: terminate" })
end

M.setup()

return M
