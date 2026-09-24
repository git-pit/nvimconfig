local M = {}

function M.setup()
  vim.pack.add({ { src = 'https://github.com/olimorris/codecompanion.nvim' } })
  require("codecompanion").setup({
    interactions = {
      chat = { adapter = "gemini" },
      inline = { adapter = "gemini" },
      cli = {
        agent = "codex",
        agents = {
          codex = {
            cmd = "codex",
            args = {},
            description = "OpenAI Codex CLI",
          },
        },
      },
    },
    adapters = {
      http = {
        gemini = function()
          return require("codecompanion.adapters").extend("gemini", {
            env = {
              GEMINI_API_KEY = "GEMINI_API_KEY",
            },
            schema = {
              model = {
                default = "gemini-3.1-flash-lite-preview",
              },
            },
          })
        end,
      },
    },
    display = {
      cli = {
        window = {
          opts = {
            number = false,
            relativenumber = false,
          },
        },
      },
    },
  })

  vim.keymap.set('', '<leader>ct', '<cmd>CodeCompanionChat Toggle<cr>')
  vim.keymap.set('n', '<leader>Ct', function()
    require('codecompanion').toggle_cli()
  end, { desc = 'Toggle Codex CLI' })
  vim.keymap.set({ 'n', 'x' }, '<leader>Cp', function()
    require('codecompanion').cli({ prompt = true })
  end, { desc = 'Edit Codex prompt' })
  vim.keymap.set('', '<leader>cc', '<cmd>CodeCompanion<cr>')
end

M.setup()

return M
