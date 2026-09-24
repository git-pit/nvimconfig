local M = {}

function M.setup()
  vim.pack.add({ { src = 'https://github.com/saghen/blink.lib' } })
  vim.pack.add({ { src = 'https://github.com/saghen/blink.cmp' } })
  require("blink.cmp").setup({
    keymap = {
      ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-e>'] = { 'hide', 'fallback' },
      ['<Tab>'] = {
        'accept',
        'fallback'
      },
      -- ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
      ['<C-y>'] = {'accept', 'fallback'},
      ['<CR>'] = {'snippet_forward', 'fallback'},
      ['<S-CR>'] = {'snippet_backward', 'fallback'},
      ['<Up>'] = { 'select_prev', 'fallback' },
      ['<Down>'] = { 'select_next', 'fallback' },
      ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
      ['<C-n>'] = { function (cmp)
        cmp.show()
      end, 'select_next', 'fallback_to_mappings' },
      ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
      ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
      ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
    },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    completion = {
      menu = { auto_show = true },
      ghost_text = { enabled = false },
    },
  })
end

M.setup()

return M
