local M = {}

function M.setup()
  vim.pack.add({ { src = 'https://github.com/ibhagwan/fzf-lua' } })
  local fzf = require('fzf-lua')
  fzf.setup({
    winopts = {
      width = 1,
      height = 1,
    }
  })
  fzf.register_ui_select()

  vim.keymap.set('n', '<leader>fl', '<cmd>FzfLua<cr>')

  vim.keymap.set('n', '<leader>ff', '<cmd>FzfLua files<cr>')
  vim.keymap.set('n', '<leader>fs', '<cmd>FzfLua live_grep<cr>')


  -- Git commands
  vim.keymap.set({ 'n', 'v' }, '<leader>fgb', '<cmd>FzfLua git_branches<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fgcb', '<cmd>FzfLua git_bcommits<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fgca', '<cmd>FzfLua git_commits<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fgd', '<cmd>FzfLua git_diff<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fgf', '<cmd>FzfLua git_files<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fgh', '<cmd>FzfLua git_hunks<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fgs', '<cmd>FzfLua git_status<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fgt', '<cmd>FzfLua git_tags<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fgw', '<cmd>FzfLua git_worktrees<cr>')

  -- Misc
  vim.keymap.set({ 'n', 'v' }, '<M-b>', '<cmd>FzfLua buffers<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fb', '<cmd>FzfLua blines<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fB', '<cmd>FzfLua buffers<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fk', '<cmd>FzfLua keymaps<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fo', '<cmd>FzfLua nvim_options<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fr', '<cmd>FzfLua registers<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fR', '<cmd>FzfLua resume<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fh', '<cmd>FzfLua history<cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>fH', '<cmd>FzfLua help_tags<cr>')

  -- LSP mappings
  vim.keymap.set({ 'n', 'v' }, '<leader>lf', '<cmd>FzfLua lsp_finder                <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>lts', '<cmd>FzfLua lsp_type_sub              <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>ltd', '<cmd>FzfLua lsp_typedefs              <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>lr', '<cmd>FzfLua lsp_references            <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>ltS', '<cmd>FzfLua lsp_type_super            <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>ld', '<cmd>FzfLua lsp_definitions           <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>lra', '<cmd>FzfLua lsp_code_actions          <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>lD', '<cmd>FzfLua lsp_declarations          <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>lI', '<cmd>FzfLua lsp_incoming_calls        <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>lO', '<cmd>FzfLua lsp_outgoing_calls        <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>li', '<cmd>FzfLua lsp_implementations       <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>lds', '<cmd>FzfLua lsp_document_symbols      <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>lwS', '<cmd>FzfLua lsp_workspace_symbols     <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>ldd', '<cmd>FzfLua lsp_document_diagnostics  <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>lwd', '<cmd>FzfLua lsp_workspace_diagnostics <cr>')
  vim.keymap.set({ 'n', 'v' }, '<leader>lws', '<cmd>FzfLua lsp_live_workspace_symbols<cr>')

  -- Search in certain path commands
  vim.keymap.set({ 'n', 'v' }, '<leader>fis', function() fzf.live_grep({ cwd = "~/.config/nvim", query = "" }) end)
  vim.keymap.set({ 'n', 'v' }, '<leader>fif', function() fzf.files({ cwd = "~/.config/nvim", query = "" }) end)

  vim.keymap.set({ 'n', 'v' }, '<leader>fIs', function() fzf.live_grep({ cwd = "~/.local/share/nvim/", query = "" }) end)
  vim.keymap.set({ 'n', 'v' }, '<leader>fIf', function() fzf.files({ cwd = "~/.local/share/nvim/", query = "" }) end)
end

M.setup()

return M
