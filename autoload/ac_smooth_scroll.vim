scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


" Script's functions/variables {{{
let s:key_count = 0

function! s:is_limit_time_over(cmd, windiv)
    let previous_timestamp = get(s:, a:cmd.a:windiv.'_timestamp_misec', [0, 0])
    let current_timestamp = reltime()
    let [sec, microsec] = reltime(previous_timestamp, current_timestamp)
    let msec = sec * 1000 + microsec / 1000
    return msec > g:ac_smooth_scroll_limit_msec
endfunction

function! s:update_key_count(cmd, windiv)
  if !g:ac_smooth_scroll_enable_accelerating
    return
  endif
  if s:is_limit_time_over(a:cmd, a:windiv)
    let s:key_count = 0
  endif
  let s:key_count += 1
endfunction

function! s:calc_step(wlcount)
  if !g:ac_smooth_scroll_enable_accelerating
    return 1
  endif
  let step = g:ac_smooth_scroll_calc_step(s:key_count, a:wlcount)
  return step
endfunction

function! s:calc_sleep_time_msec(sleep_time_msec)
  return g:ac_smooth_scroll_calc_sleep_time_msec(s:key_count, a:sleep_time_msec)
endfunction

function! s:calc_skip_redraw_line_size()
  return g:ac_smooth_scroll_calc_skip_redraw_line_size(s:key_count, g:ac_smooth_scroll_skip_redraw_line_size)
endfunction

function! s:scroll(cmd, step, sleep_time_msec, skip_redraw_line_size, wlcount)
  let move_disp_cmd = 'normal! '
  if a:cmd == 'j'
    " Scroll down.
    let tob = line('$')
    let vbl = 'w$'
    let move_disp_cmd = move_disp_cmd."\<C-E>"
  else
    " Scroll up.
    let tob = 1
    let vbl = 'w0'
    let move_disp_cmd = move_disp_cmd."\<C-Y>"
  endif

  let sleep_cmd = 'sleep '.a:sleep_time_msec.'m'

  let i = 0
  let j = 0
  while i < a:wlcount
    let step = a:step
    let rest = a:wlcount - i
    if line(vbl) == tob
      execute 'normal! '.rest.a:cmd
      break
    endif
    let i += step

    if rest < step
      let step = rest
    endif
    execute 'normal! '.step.a:cmd
    let k = 0
    while k < step
      let k +=1
      execute move_disp_cmd
    endwhile

    if i < a:wlcount && j >= a:skip_redraw_line_size
      let j = 0
      redraw
    else
      let j = j + 1
    endif

    if a:sleep_time_msec > 0
      execute sleep_cmd
    endif
  endwhile
endfunction
" }}}


" Global functions {{{
function! ac_smooth_scroll#scroll(cmd, windiv, sleep_time_msec)
  " Disable highlight the screen line of the cursor,
  " because will make screen redrawing slower.
  let save_cul = &cul
  if save_cul
    set nocul
  endif

  call s:update_key_count(a:cmd, a:windiv)

  let wlcount = winheight(0) / a:windiv
  let step = s:calc_step(wlcount)
  let sleep_time_msec = s:calc_sleep_time_msec(a:sleep_time_msec)
  let skip_redraw_line_size = s:calc_skip_redraw_line_size()

  call s:scroll(a:cmd, step, sleep_time_msec, skip_redraw_line_size, wlcount)

  let s:{a:cmd}{a:windiv}_timestamp_misec = reltime()

  if save_cul | set cul | endif
endfunction
" }}}


let &cpo = s:save_cpo
unlet s:save_cpo
