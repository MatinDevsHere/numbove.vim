" autoload/wordjump.vim - Core functionality

let s:state = {
    \ 'enabled': 1,
    \ 'timer': -1,
    \ 'last_lnum': -1,
    \ 'last_buf': -1,
    \ 'floats': [],
    \ 'cooldown': 0,
    \ 'cache': {'lnum': -1, 'text': '', 'positions': []}
\ }

function! wordjump#clear() abort
    if s:state.timer != -1
        call timer_stop(s:state.timer)
        let s:state.timer = -1
    endif
    call s:clear_floats()
endfunction

function! wordjump#toggle() abort
    let s:state.enabled = !s:state.enabled
    if s:state.enabled
        echo "WordJump: Enabled"
    else
        call wordjump#clear()
        echo "WordJump: Disabled"
    endif
endfunction

function! wordjump#schedule_update() abort
    if !s:state.enabled || mode() !=# 'n'
        return
    endif

    let current_buf = bufnr('%')
    let current_lnum = line('.')
    let now = reltime()

    " Check if we're still in the same valid context
    if current_buf != s:state.last_buf || current_lnum != s:state.last_lnum
        call wordjump#clear()
        let s:state.last_buf = current_buf
        let s:state.last_lnum = current_lnum
    endif

    " Rate limiting
    if s:state.timer != -1 || s:state.cooldown > str2float(reltimestr(now))
        return
    endif

    let s:state.timer = timer_start(g:wordjump_delay, function('s:handle_update'))
endfunction

function! s:handle_update(...) abort
    let s:state.timer = -1
    let s:state.cooldown = str2float(reltimestr(reltime())) + (g:wordjump_delay / 1000.0)
    
    if !s:state.enabled || mode() !=# 'n' || line('.') != s:state.last_lnum
        return
    endif

    call s:update_numbers()
endfunction

function! s:update_numbers() abort
    let lnum = line('.')
    let text = getline('.')
    let win = nvim_get_current_win()
    let buf = bufnr('%')

    " Use cached positions if available
    if lnum == s:state.cache.lnum && text == s:state.cache.text
        let positions = s:state.cache.positions
    else
        let positions = s:get_word_starts()
        let s:state.cache = {
            \ 'lnum': lnum,
            \ 'text': text,
            \ 'positions': positions
        \ }
    endif

    let cursor_col = col('.') - 1
    let targets = s:calculate_targets(positions, cursor_col)
    call s:render_numbers(targets, win, lnum)
endfunction

function! s:get_word_starts() abort
    let line = getline('.')
    let positions = []
    let col = 0

    while 1
        let [match_start, match_end] = matchstrpos(line, '\v(^|\S)\zs\S', col)
        if match_start == -1 | break | endif
        call add(positions, match_start)
        let col = match_end
    endwhile

    return positions
endfunction

function! s:calculate_targets(positions, cursor_col) abort
    let forward = []
    let backward = []
    let on_word = 0

    for pos in a:positions
        if pos == a:cursor_col
            let on_word = 1
        elseif pos > a:cursor_col
            call add(forward, pos)
        else
            call add(backward, pos)
        endif
    endfor

    let targets = []
    if on_word | call add(targets, {'pos': a:cursor_col, 'label': 0}) | endif

    " Process forward targets
    let i = 1
    for pos in sort(forward)
        if i > g:wordjump_max_targets | break | endif
        call add(targets, {'pos': pos, 'label': i % 10})
        let i += 1
    endfor

    " Process backward targets
    let i = 1
    for pos in sort(backward, function('s:reverse_compare'))
        if i > g:wordjump_max_targets | break | endif
        call add(targets, {'pos': pos, 'label': i % 10})
        let i += 1
    endfor

    return targets
endfunction

function! s:render_numbers(targets, win, lnum) abort
    call s:clear_floats()

    for target in a:targets
        let screenpos = screenpos(a:win, a:lnum, target.pos + 1)
        if screenpos.row <= 0 | continue | endif

        let buf = nvim_create_buf(v:false, v:true)
        call nvim_buf_set_lines(buf, 0, -1, v:false, [string(target.label)])

        let color_idx = (target.label % 6) + 1
        let opts = {
            \ 'relative': 'win',
            \ 'win': a:win,
            \ 'row': screenpos.row - 2,
            \ 'col': screenpos.col - 1,
            \ 'width': 1,
            \ 'height': 1,
            \ 'focusable': v:false,
            \ 'style': 'minimal'
        \ }

        let float_win = nvim_open_win(buf, v:false, opts)
        call nvim_win_set_option(float_win, 'winhl', 'Normal:WordJump' . color_idx)
        call add(s:state.floats, float_win)
    endfor
endfunction

function! s:clear_floats() abort
    for win in s:state.floats
        if nvim_win_is_valid(win)
            call nvim_win_close(win, v:true)
        endif
    endfor
    let s:state.floats = []
endfunction

function! s:reverse_compare(a, b) abort
    return a:a > a:b ? -1 : 1
endfunction
