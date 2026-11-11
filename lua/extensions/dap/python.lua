local M = {}

function M.setup(dap)
  local adapter = vim.fn.exepath('debugpy-adapter')
  if adapter == '' then
    vim.notify('Python debugging requires debugpy-adapter', vim.log.levels.WARN)
    return
  end

  -- Resolved at launch, so a venv activated after startup is picked up.
  -- Without one, use the python on PATH instead of the adapter's own interpreter.
  local function python_path()
    local bin = vim.fn.has('win32') == 1 and '/Scripts/python' or '/bin/python'
    local candidates = {}
    local venv = os.getenv('VIRTUAL_ENV') or os.getenv('CONDA_PREFIX')
    if venv then candidates[#candidates + 1] = venv .. bin end
    candidates[#candidates + 1] = vim.fn.getcwd() .. '/.venv' .. bin
    candidates[#candidates + 1] = vim.fn.getcwd() .. '/venv' .. bin
    for _, candidate in ipairs(candidates) do
      if vim.fn.executable(candidate) == 1 then return candidate end
    end
    local python = vim.fn.exepath('python3')
    if python == '' then python = vim.fn.exepath('python') end
    return python ~= '' and python or nil
  end

  dap.adapters.python = {
    type = 'executable',
    command = adapter,
  }
  dap.configurations.python = {
    {
      -- The first three options are required by nvim-dap
      type = 'python', -- the type here established the link to the adapter definition: `dap.adapters.python`
      request = 'launch',
      name = 'Python: Launch file',
      program = '${file}', -- This configuration will launch the current file if used.
      pythonPath = python_path,
      console = 'integratedTerminal',
    },
  }
end

return M
