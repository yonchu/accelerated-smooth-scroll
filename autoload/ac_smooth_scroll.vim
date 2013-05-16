scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


" Script's functions/variables {{{
let s:key_count = 0

function! s:get_elapsed_time(cmd, windiv)
    let previous_timestamp = get(s:, a:cmd.a:windiv.'_timestamp_misec', [0, 0])
    let current_timestamp = reltime()
    let [sec, microsec] = reltime(previous_timestamp, current_timestamp)
    let msec = sec * 1000 + microsec / 1000
    return msec
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
  " Make the command to move display.
  " Calc tob and vbl.
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

  " Make the command to sleep.
  let sleep_cmd = 'sleep '.a:sleep_time_msec.'m'

  let i = 0
  let j = 0
  while i < a:wlcount
    let rest = a:wlcount - i
    " Move cursor without moving display, if top or end of file is displaied.
    if line(vbl) == tob
      execute 'normal! '.rest.a:cmd
      break
    endif

    " Calc cursor step count.
    let i += a:step
    let step = a:step
    if rest < step
      let step = rest
    endif

    " Move cursor.
    execute 'normal! '.step.a:cmd
    let k = 0
    " Move display.
    while k < step
      let k +=1
      execute move_disp_cmd
    endwhile

    if i < a:wlcount
      " Redraw.
      if j >= a:skip_redraw_line_size
        let j = 0
        redraw
      else
        let j = j + 1
      endif
      " Sleep.
      if a:sleep_time_msec > 0
        execute sleep_cmd
      endif
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

  let elapsed_time = s:get_elapsed_time(a:cmd, a:windiv)

  " Check min time.
  if elapsed_time >= 0 && elapsed_time < g:ac_smooth_scroll_min_limit_msec
    return
  endif

  " Check max time.
  if g:ac_smooth_scroll_enable_accelerating
    if elapsed_time > g:ac_smooth_scroll_max_limit_msec
      let s:key_count = 0
    endif
    let s:key_count += 1
  endif

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
