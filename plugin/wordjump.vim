" plugin/wordjump.vim - Main plugin file

if exists('g:loaded_wordjump')
    finish
endif
let g:loaded_wordjump = 1

" Configuration
let g:wordjump_delay = get(g:, 'wordjump_delay', 100)
let g:wordjump_max_targets = get(g:, 'wordjump_max_targets', 20)

" Highlight groups
hi def WordJump1 guifg=#FFD700 guibg=#404040
hi def WordJump2 guifg=#00FF00 guibg=#404040
hi def WordJump3 guifg=#FFA500 guibg=#404040
hi def WordJump4 guifg=#FF0000 guibg=#404040
hi def WordJump5 guifg=#800080 guibg=#404040
hi def WordJump6 guifg=#A52A2A guibg=#404040

" Mappings
if !exists('g:wordjump_disable_default_mappings')
    nnoremap <silent> <Esc> :call wordjump#clear()<CR>:nohlsearch<CR>
endif

" Commands
if !exists('g:wordjump_disable_default_commands')
    command! WordJumpToggle call wordjump#toggle()
endif

" Autocommands
augroup WordJump
    autocmd!
    autocmd CursorMoved,CursorMovedI,ModeChanged * call wordjump#schedule_update()
    autocmd WinScrolled,BufEnter,TextChanged,InsertEnter * call wordjump#clear()
augroup END
