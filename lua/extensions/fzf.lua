local M = {}

function M.setup()
  vim.pack.add({ { src = 'https://github.com/ibhagwan/fzf-lua' } })
  require('fzf-lua').setup({ })

  vim.keymap.set('n', '<leader>fl', '<cmd>FzfLua<cr>')

  vim.keymap.set('n', '<leader>ff', '<cmd>FzfLua files<cr>')


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
end

M.setup()

return M
