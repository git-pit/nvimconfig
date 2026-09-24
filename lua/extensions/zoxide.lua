local M = {}

function M.setup()
  local fzf = require('fzf-lua')
  local function zoxide_manager()
    fzf.fzf_exec('zoxide query --list', {
      prompt = 'Zoxide ',
      actions = {
        ['default'] = function(selected)
          if #selected == 1 then
            vim.fn.chdir(selected[1])
          end
        end,
        ['ctrl-x'] = function(selected)
          if selected and #selected > 0 then
            local dir = selected[1]
            vim.system({'zoxide', 'remove', dir})
            zoxide_manager()
          end
        end,
        ['ctrl-a'] = function ()
          vim.system({'zoxide', 'add', vim.fn.getcwd()})
          zoxide_manager()
        end
      },
    })
  end
  vim.keymap.set({'', '!', 't'}, '<M-z>', function () zoxide_manager() end)
end

M.setup()

return M
