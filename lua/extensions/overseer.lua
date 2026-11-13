local M = {}

function M.setup()
  vim.pack.add({ { src = 'https://github.com/stevearc/overseer.nvim' } })
  local over = require("overseer")
  over.setup({
    task_list = {
      direction = "left",
      keymaps = {
        ["r"] = { "keymap.run_action", opts = { action = "restart" }, desc = "Restart task" },
        ["s"] = { "keymap.run_action", opts = { action = "stop" }, desc = "Stop task" },
      },
    },
  })

  vim.api.nvim_create_user_command("Make", function(params)
    -- Insert args at the '$*' in the makeprg
    local cmd, num_subs = vim.o.makeprg:gsub("%$%*", params.args)
    if num_subs == 0 then
      cmd = cmd .. " " .. params.args
    end
    local task = require("overseer").new_task({
      cmd = vim.fn.expandcmd(cmd),
      components = {
        {
          "on_output_quickfix",
          open = not params.bang,
          open_height = 8,
          errorformat = vim.o.errorformat,
        },
        "default",
      },
    })
    task:start()
  end, {
    desc = "Run your makeprg as an Overseer task",
    nargs = "*",
    bang = true,
  })

  -- Keymaps
  vim.keymap.set('', '<leader>or', '<cmd>OverseerRun<cr>')
  vim.keymap.set('', '<leader>ot', '<cmd>OverseerToggle<cr>')

  vim.keymap.set('', '<leader>ma', '<cmd>Make<cr>')
  vim.keymap.set('', '<leader>mr', '<cmd>Make run<cr>')
end

return M
