" Set up default mappings and commands
if !exists('g:wordjump_disable_default_mappings')
    nnoremap <silent> <Esc> :call wordjump#clear_floats()<CR>:nohlsearch<CR>
endif

if !exists('g:wordjump_disable_default_commands')
    command! TriggerNums call wordjump#toggle_enabled()
endif

" Set up autocommands
augroup WordJumpNumbers
    autocmd!
    autocmd CursorMoved,CursorMovedI,ModeChanged * call wordjump#handle_cursor_move()
    autocmd WinScrolled,BufEnter,TextChanged * call wordjump#show_numbers()
augroup END

" Define highlight groups
hi def WordJump1 guifg=#FFD700 guibg=#404040
hi def WordJump2 guifg=#00FF00 guibg=#404040
hi def WordJump3 guifg=#FFA500 guibg=#404040
hi def WordJump4 guifg=#FF0000 guibg=#404040
hi def WordJump5 guifg=#800080 guibg=#404040
hi def WordJump6 guifg=#A52A2A guibg=#404040
