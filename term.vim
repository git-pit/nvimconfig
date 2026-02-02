function! s:TermEnter(_)
  if getbufvar(bufnr(), 'term_insert', 0)
    startinsert
    call setbufvar(bufnr(), 'term_insert', 0)
  endif
endfunction

function! <SID>TermExec(cmd)
  let b:term_insert = 1
  execute a:cmd
endfunction

augroup Term
  autocmd CmdlineLeave,WinEnter,BufWinEnter * call timer_start(500, function('s:TermEnter'), {})
augroup end

augroup term_cmds
    autocmd!
    autocmd TermOpen term://* startinsert
augroup END

tnoremap <silent> <C-w>.      <C-W>
tnoremap <silent> <C-w><C-.>  <C-W>
tnoremap <silent> <C-w><C-\>  <C-\>
tnoremap <silent> <C-w>N      <C-\><C-N>
tnoremap <silent> <C-w>:      <C-\><C-N>:call <SID>TermExec('call feedkeys(":")')<CR>
tnoremap <silent> <C-w>"     <C-\><C-N>:execute "normal \"" . nr2char(getchar()) . "pi"<cr>
tnoremap <silent> <C-w><C-W>  <cmd>call <SID>TermExec('wincmd w')<CR>
tnoremap <silent> <C-w>h      <cmd>call <SID>TermExec('wincmd h')<CR>
tnoremap <silent> <C-w>j      <cmd>call <SID>TermExec('wincmd j')<CR>
tnoremap <silent> <C-w>k      <cmd>call <SID>TermExec('wincmd k')<CR>
tnoremap <silent> <C-w>l      <cmd>call <SID>TermExec('wincmd l')<CR>
tnoremap <silent> <C-w><C-H>  <cmd>call <SID>TermExec('wincmd h')<CR>
tnoremap <silent> <C-w><C-J>  <cmd>call <SID>TermExec('wincmd j')<CR>
tnoremap <silent> <C-w><C-K>  <cmd>call <SID>TermExec('wincmd k')<CR>
tnoremap <silent> <C-w><C-L>  <cmd>call <SID>TermExec('wincmd l')<CR>
tnoremap <silent> <C-w>gT     <cmd>call <SID>TermExec('tabp')<CR>
tnoremap <silent> <C-w>gt     <cmd>call <SID>TermExec('tabn')<CR>
tnoremap <silent> <C-w>1gt     <cmd>call <SID>TermExec('tabfirst')<CR>
tnoremap <silent> <C-w>2gt     <cmd>call <SID>TermExec('tabnext 2')<CR>
tnoremap <silent> <C-w>3gt     <cmd>call <SID>TermExec('tabnext 3')<CR>
tnoremap <silent> <C-w>4gt     <cmd>call <SID>TermExec('tabnext 4')<CR>
tnoremap <silent> <C-w>5gt     <cmd>call <SID>TermExec('tabnext 5')<CR>
tnoremap <silent> <C-w>6gt     <cmd>call <SID>TermExec('tabnext 6')<CR>
tnoremap <silent> <C-w>7gt     <cmd>call <SID>TermExec('tabnext 7')<CR>
tnoremap <silent> <C-w>8gt     <cmd>call <SID>TermExec('tabnext 8')<CR>
tnoremap <silent> <C-w>9gt     <cmd>call <SID>TermExec('tabnext 9')<CR>
tnoremap <silent> <C-w>10gt     <cmd>call <SID>TermExec('tabnext 10')<CR>

