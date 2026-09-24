local M = {}

function M.setup()
  -- Package name changed from `fff.nvim` to `fff`. If you installed fff.nvim before, clean with `:packdel fff.nvim`
  vim.pack.add({ 'https://github.com/dmtrKovalenko/fff' })

  require('fff').setup({
    prompt = '🔍 ',
    max_results = 100,
    max_threads = 8,
    layout = {
      height = 1,
      width = 1,
      prompt_position = 'top',    -- or 'top'
      preview_position = 'right', -- 'left' | 'right' | 'top' | 'bottom'
      preview_size = 0.67,
    },
    -- find_files specific rendering
    file_picker = {
      current_file_label = '(curr)',    -- virtual text marking the buffer the picker was opened from
      fuzzy_query_highlighting = true, -- true to highlight fuzzy query matches, not just the literal query
    },
    keymaps = {
      close = '<Esc>',
      select = '<CR>',
      select_split = '<C-s>',
      select_vsplit = '<C-v>',
      select_tab = '<C-t>',
      move_up = { '<Up>', '<C-p>', '<C-k>'},
      move_down = { '<Down>', '<C-n>', '<C-j>'},
      preview_scroll_up = '<C-u>',
      preview_scroll_down = '<C-d>',
      toggle_debug = '<F2>',
      cycle_grep_modes = '<S-Tab>',
      insert_newline_escape = '<C-CR>',
      -- grep mode only: jump cursor to first match of next/prev file group
      grep_jump_to_prev_file = { '<C-A-p>', '<C-A-k>', '<A-Up>' },
      grep_jump_to_next_file = { '<C-A-n>', '<C-A-j>', '<A-Down>' },
      cycle_previous_query = '<C-Up>',
      cycle_forward_query = '<C-Down>',
      -- unbound by default, wipes the whole input line
      -- clear_query = '<C-u>', -- overrides preview_scroll_up in insert mode
      toggle_select = '<Tab>',
      send_to_quickfix = '<C-q>',
      focus_list = '<leader>l',
      focus_preview = '<leader>p',
    },
    frecency = {
      enabled = true,
      db_path = vim.fn.stdpath('cache') .. '/fff_nvim',
    },
    history = {
      enabled = true,
      db_path = vim.fn.stdpath('data') .. '/fff_queries',
      min_combo_count = 3,
      combo_boost_score_multiplier = 100,
    },
    git = {
      status_text_color = true, -- true to color filenames by git status
      -- files that participated in the last N configured commits will get scoring bonus
      recency = {
        enabled = false,            -- boost files from recent commits of the current branch
        max_commits = 10,          -- analyze the last N branch-specific commits
        max_files_per_commit = 50, -- skip bulk commits touching more files than this
      },
    },
    select = {
      -- Return winid to open the chosen file in, or nil to open in the original window
      -- select_window = function(current_buf, action) --[[ default impl ]] end,
    },
    suggestions = {
      enabled = true,           -- when a query has no results, look them up in the other mode (files <-> grep) and show as a hint
      grep_time_budget_ms = 50, -- hard cap for the grep hint in file mode; it is skipped until content indexing finishes
    },
    debug = {
      enabled = true,      -- show the file info panel next to the preview
      show_scores = false, -- inline scores in the file list
      -- Per-section toggles for the file info panel. Accepts a boolean shorthand
      -- (`show_file_info = true|false`) to flip everything at once. The panel
      -- adapts to width: narrow renders sections vertically, wide renders them
      -- as a two-column grid. Disable a section to also shrink the panel.
      show_file_info = {
        file_info = true,        -- size, type, git status, frecency
        score_breakdown = false, -- total + match type, bonuses, modifiers, penalty
        -- modified + accessed timestamps; pass a table to hide individual rows:
        --   timings = { modified = false, accessed = true }
        timings = true,
        full_path = true, -- relative path at the bottom (wraps if too long)
      },
    },
    logging = {
      enabled = false,
      -- logs will be written in a parent directory of this file path in files like
      -- `<stem>+<UTC-timestamp>+<pid>.<ext>`. Run :FFFOpenLog to open current one
      log_file = vim.fn.stdpath('log') .. '/fff.log',
      log_level = 'info',
      retain_runs = 20,
    },
  })

  vim.keymap.set({'', '!', 't'}, '<M-f>', function() require('fff').find_files() end, { desc = 'FFFind files' })
  vim.keymap.set({'', '!', 't'}, '<M-r>', function() require('fff').live_grep() end, { desc = 'FFF Live grep' })
  vim.keymap.set({''}, '<leader>fw', function() require('fff').live_grep_under_cursor() end, { desc = 'FFF Live grep' })
end

M.setup()

return M
