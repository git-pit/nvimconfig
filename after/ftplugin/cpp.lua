-- Align access labels with the class and keep `std:` at the current indent.
vim.opt_local.cinoptions:append({ 'g0', 'L0' })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '') .. '|setlocal cinoptions<'

vim.keymap.set('n', "<leader>so", [[:s/\s\{-}\zs\(\w.*\)\ze/std::cout << "\1" << std::endl;<cr>:noh<cr>]])
