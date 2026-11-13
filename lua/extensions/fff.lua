local M = {}

function M.setup()
  -- Package name changed from `fff.nvim` to `fff`. If you installed fff.nvim before, clean with `:packdel fff.nvim`
  vim.pack.add({ 'https://github.com/dmtrKovalenko/fff' })

  require('fff').setup({
    prompt = '🔍 ',
    layout = {
      height = 1,
      width = 1,
      prompt_position = 'top',
      preview_size = 0.67,
    },
    max_threads = 8,
    file_picker = {
      current_file_label = '(curr)',
      fuzzy_query_highlighting = true,
    },
    keymaps = {
      move_up = { '<Up>', '<C-p>', '<C-k>' },
      move_down = { '<Down>', '<C-n>', '<C-j>' },
      grep_jump_to_prev_file = { '<C-A-p>', '<C-A-k>', '<A-Up>' },
      grep_jump_to_next_file = { '<C-A-n>', '<C-A-j>', '<A-Down>' },
    },
    git = {
      status_text_color = true, -- color filenames by git status
      recency = { enabled = false },
    },
    debug = {
      enabled = true, -- show the file info panel next to the preview
      show_file_info = { score_breakdown = false },
    },
    logging = { enabled = false },
  })

  vim.keymap.set({'', '!', 't'}, '<M-f>', function() require('fff').find_files() end, { desc = 'FFFind files' })
  vim.keymap.set({'', '!', 't'}, '<M-r>', function() require('fff').live_grep() end, { desc = 'FFF Live grep' })
  vim.keymap.set({''}, '<leader>fw', function() require('fff').live_grep_under_cursor() end, { desc = 'FFF Live grep word under cursor' })
end

return M
