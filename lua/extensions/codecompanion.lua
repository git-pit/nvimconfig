local M = {}

function M.setup()
  vim.pack.add({ { src = 'https://github.com/olimorris/codecompanion.nvim' } })
  require("codecompanion").setup({
    interactions = {
      -- chat = { adapter = "gemini" },
      -- inline = { adapter = "gemini" },
      cli = {
        agent = "claude",
        agents = {
          claude = {
            cmd = "claude",
            args = {},
            description = "claude",
          },
        },
      },
    },
    -- adapters = {
    --   http = {
    --     gemini = function()
    --       return require("codecompanion.adapters").extend("gemini", {
    --         env = {
    --           GEMINI_API_KEY = "GEMINI_API_KEY",
    --         },
    --         schema = {
    --           model = {
    --             default = "gemini-3.1-flash-lite-preview",
    --           },
    --         },
    --       })
    --     end,
    --   },
    -- },
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

  vim.keymap.set('n', '<leader>ct', function()
    require('codecompanion').toggle_cli()
  end, { desc = 'Toggle Codex CLI' })
  vim.keymap.set({ 'n', 'x' }, '<leader>cp', function()
    require('codecompanion').cli({ prompt = true })
  end, { desc = 'Edit Codex prompt' })
  vim.keymap.set('x', '<leader>cs', ':CodeCompanionCLI<cr>', { desc = 'Send selection to Claude CLI' })
  vim.keymap.set('x', '<leader>ce', function()
    local cc = require('codecompanion')
    local session = require('codecompanion.interactions.cli').last_cli()
    if not (session and session.provider:is_running()) then
      -- Typing into Claude's startup prompts makes it exit, so just start it
      cc.cli()
      vim.notify('Started Claude. Answer its prompt, then press <leader>ce again.')
      return
    end
    -- Clear the running Claude session instead of spawning a new one
    -- Send directly so the selection context isn't prepended to the command
    session:send('/clear', { submit = true })
    cc.cli('Can you explain #{this}?', { submit = true })
  end, { desc = 'Explain selection in new Claude chat' })
end

M.setup()

return M
