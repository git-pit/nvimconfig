local M = {}

function M.setup(dap, overseer)
  local function make_project_dir()
    local file = vim.api.nvim_buf_get_name(0)
    local start = file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
    local makefile = vim.fs.find("Makefile", { path = start, upward = true })[1]
    return makefile and vim.fs.dirname(makefile) or vim.fn.getcwd()
  end

  -- Dry-run make without blocking the UI. nvim-dap evaluates config functions
  -- inside a coroutine, so yield until make finishes when possible.
  local function make_dry_run(dir)
    local cmd = { "make", "-B", "-n" }
    local opts = { cwd = dir, text = true, timeout = 10000 }
    local co, is_main = coroutine.running()
    if co and not is_main then
      vim.system(cmd, opts, vim.schedule_wrap(function(result)
        coroutine.resume(co, result)
      end))
      return coroutine.yield()
    end
    return vim.system(cmd, opts):wait()
  end

  local function find_make_executable()
    local dir = make_project_dir()
    if vim.fn.filereadable(dir .. "/Makefile") == 1 then
      local result = make_dry_run(dir)
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
    local ok, path = pcall(vim.fn.input, "Executable: ", dir .. "/", "file")
    if not ok or path == "" or vim.fn.isdirectory(path) == 1 then
      return dap.ABORT
    end
    return path
  end

  overseer.register_template({
    name = "make",
    builder = function()
      return {
        cmd = { "make" },
        cwd = make_project_dir(),
        components = {
          {
            "on_output_quickfix",
            open_on_exit = "failure",
            open_height = 8,
            errorformat = vim.o.errorformat,
          },
          "default",
        },
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
      -- Return a copy so the original config definition is left untouched.
      return vim.tbl_extend("force", {}, config, { console = "integratedTerminal" })
    end
    return config
  end

  local fallback = {
    {
      name = "Build with make and debug",
      type = "lldb",
      request = "launch",
      preLaunchTask = "make",
      program = find_make_executable,
      cwd = make_project_dir,
      stopOnEntry = false,
      console = "integratedTerminal",
    },
    {
      name = "Build with make and debug with args",
      type = "lldb",
      request = "launch",
      preLaunchTask = "make",
      program = find_make_executable,
      cwd = make_project_dir,
      args = function() return vim.split(vim.fn.input("Args: "), ' ', { trimempty = true }) end,
      stopOnEntry = false,
      console = "integratedTerminal",
    },
    {
      name = "Debug executable (no build)",
      type = "lldb",
      request = "launch",
      program = find_make_executable,
      cwd = make_project_dir,
      stopOnEntry = false,
      console = "integratedTerminal",
    },
  }
  dap.providers.configs["cpp.make_fallback"] = function(bufnr)
    local filetype = vim.bo[bufnr].filetype
    if filetype ~= "c" and filetype ~= "cpp" then
      return {}
    end
    -- Only a launch.json that has LLDB configs replaces the fallback.
    local ok, project_configs = pcall(require("dap.ext.vscode").getconfigs)
    if ok then
      for _, config in ipairs(project_configs) do
        if config.type == "lldb" or config.type == "lldb-dap" then
          return {}
        end
      end
    end
    if vim.fn.filereadable(make_project_dir() .. "/Makefile") == 0 then
      return { fallback[3] }
    end
    return fallback
  end
end

return M
