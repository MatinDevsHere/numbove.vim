" wordjump.vim - Core functionality for WordJump plugin

let s:floats = []
let s:enabled = 1

function! wordjump#clear_floats() abort
    for win in s:floats
        if nvim_win_is_valid(win)
            call nvim_win_close(win, v:true)
        endif
    endfor
    let s:floats = []
endfunction

function! s:reverse_compare(a, b) abort
    return a:a > a:b ? -1 : 1
endfunction

function! wordjump#get_word_starts() abort
    let original_pos = getpos('.')
    let original_view = winsaveview()
    let lnum = original_pos[1]
    let positions = []
    let prev_col = -1

    call cursor(lnum, 1)
    while 1
        let pos = getpos('.')
        if pos[1] != lnum || pos[2] == prev_col
            break
        endif
        let prev_col = pos[2]
        let line = getline('.')
        if pos[2] <= len(line)
            call add(positions, pos[2] - 1) " Convert to 0-based index
        endif
        normal! w
    endwhile

    call setpos('.', original_pos)
    call winrestview(original_view)
    let cursor_col = original_pos[2] - 1 " Convert to 0-based index

    return [positions, cursor_col]
endfunction

function! wordjump#show_numbers() abort
    if !s:enabled | return | endif
    call wordjump#clear_floats()
    if mode() !=# 'n' | return | endif

    let win = nvim_get_current_win()
    let lnum = nvim_win_get_cursor(win)[0]
    let [positions, cursor_col] = wordjump#get_word_starts()

    let forward = []
    let backward = []
    let on_word_start = 0

    for pos in positions
        if pos == cursor_col
            let on_word_start = 1
        elseif pos > cursor_col
            call add(forward, pos)
        else
            call add(backward, pos)
        endif
    endfor

    call sort(forward)
    call sort(backward, function('s:reverse_compare'))

    let targets = []
    if on_word_start
        call add(targets, {'pos': cursor_col, 'label': 0})
    endif

    " Process forward targets
    let i = 1
    for pos in forward
        let label = (i % 10 == 0) ? 0 : (i % 10)
        call add(targets, {'pos': pos, 'label': label})
        let i += 1
    endfor

    " Process backward targets
    let i = 1
    for pos in backward
        let label = (i % 10 == 0) ? 0 : (i % 10)
        call add(targets, {'pos': pos, 'label': label})
        let i += 1
    endfor

    " Create floating windows
    for target in targets
        let screenpos = screenpos(win, lnum, target.pos + 1)
        if screenpos.row > 0
            let buf = nvim_create_buf(v:false, v:true)
            call nvim_buf_set_lines(buf, 0, -1, v:false, [string(target.label)])

            let color_idx = (target.label % 6) + 1
            let opts = {
                        \ 'relative': 'win',
                        \ 'win': win,
                        \ 'row': screenpos.row - 2,
                        \ 'col': screenpos.col - 1,
                        \ 'width': 1,
                        \ 'height': 1,
                        \ 'focusable': v:false,
                        \ 'style': 'minimal'
                        \ }

            let float_win = nvim_open_win(buf, v:false, opts)
            call nvim_win_set_option(float_win, 'winhl', 'Normal:WordJump' . color_idx)
            call add(s:floats, float_win)
        endif
    endfor
endfunction

function! wordjump#handle_cursor_move() abort
    if s:enabled && mode() ==# 'n'
        call wordjump#show_numbers()
    else
        call wordjump#clear_floats()
    endif
endfunction

function! wordjump#toggle_enabled() abort
    let s:enabled = !s:enabled
    if s:enabled
        call wordjump#show_numbers()
        echo "Word jump numbers: enabled"
    else
        call wordjump#clear_floats()
        echo "Word jump numbers: disabled"
    endif
endfunction
