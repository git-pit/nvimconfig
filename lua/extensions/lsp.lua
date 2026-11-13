local M = {}

function M.setup()
  vim.pack.add({ { src = 'https://github.com/neovim/nvim-lspconfig' } })
  require('extensions.cppdocs').setup()

  -- Mason's clangd is upstream LLVM and doesn't know Apple clang's implicit include
  -- dirs (e.g. /usr/local/include), so let it ask the real compiler for them.
  vim.lsp.config('clangd', {
    cmd = { 'clangd', '--query-driver=/usr/bin/c++,/usr/bin/cc,/usr/bin/clang,/usr/bin/clang++' },
  })

  -- Servers are enabled by mason-lspconfig (extensions.mason) and get their completion
  -- capabilities from blink.cmp. K, grr, gra, grn and gri are Neovim defaults.
  vim.api.nvim_create_autocmd("LspAttach", {
    desc = 'LSP actions',
    callback = function(event)
      local opts = { buffer = event.buf }

      vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, opts)
      vim.keymap.set('n', '<F4>', vim.lsp.buf.code_action, opts)
      vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
      vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, opts)
      vim.keymap.set({ 'n', 'x' }, '<F3>', function()
        vim.lsp.buf.format({ async = true })
      end, opts)
    end,
  })
end

return M
