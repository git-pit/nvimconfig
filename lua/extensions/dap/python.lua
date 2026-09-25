local M = {}

function M.setup(dap)
  local venv_path = os.getenv('VIRTUAL_ENV') or os.getenv('CONDA_PREFIX')
  dap.adapters.python = {
    type = 'executable',
    command = vim.fn.exepath('debugpy-adapter'),
  }
  dap.configurations.python = {
    {
      -- The first three options are required by nvim-dap
      type = 'python', -- the type here established the link to the adapter definition: `dap.adapters.python`
      request = 'launch',
      name = 'Python: Launch file',
      program = '${file}', -- This configuration will launch the current file if used.
      -- venv on Windows uses Scripts instead of bin
      pythonPath = venv_path
          and ((vim.fn.has('win32') == 1 and venv_path .. '/Scripts/python') or venv_path .. '/bin/python')
          or nil,
      console = 'integratedTerminal',
    },
  }
end

return M
