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

augroup ac-smooth-scroll-dummy-group
  autocmd!
augroup END
autocmd ac-smooth-scroll-dummy-group User AcSmoothScrollEnter silent! execute ''
autocmd ac-smooth-scroll-dummy-group User AcSmoothScrollLeave silent! execute ''

let s:cache_command = {}
function! s:doautocmd_user(command)
  if !has_key(s:cache_command, a:command)
    if v:version > 703 || v:version == 703 && has("patch438")
      let s:cache_command[a:command] = "doautocmd <nomodeline> User " . a:command
    else
      let s:cache_command[a:command] = "doautocmd User " . a:command
    endif
  endif
  execute s:cache_command[a:command]
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

function! s:next_line_num(cmd, lnum, step)
  if a:cmd == 'j'
    let lnum = a:lnum + a:step
  else
    let lnum = a:lnum - a:step
    if lnum < 1
      let lnum = 1
    endif
  endif
  return lnum
endfunction

function! s:scroll(cmd, step, sleep_time_msec, skip_redraw_line_size, wlcount, is_vmode)
  " Setup for visual mode.
  if a:is_vmode
    if a:cmd == 'j'
      call setpos('.', getpos("'>"))
    else
      call setpos('.', getpos("'<"))
    endif
    let save_lazyredraw = &lazyredraw
    if !save_lazyredraw
      set lazyredraw
    endif
  endif

  " Make the command to move display.
  " Calc tob and vbl.
  if a:cmd == 'j'
    " Scroll down.
    let tob = line('$')
    let vbl = 'w$'
    let move_disp_cmd = "\<C-E>"
  else
    " Scroll up.
    let tob = 1
    let vbl = 'w0'
    let move_disp_cmd = "\<C-Y>"
  endif

  " Make the command to sleep.
  let sleep_cmd = 'sleep '.a:sleep_time_msec.'m'

  " Loop start.
  let i = 0
  let j = 0
  while i < a:wlcount
    let rest = a:wlcount - i
    " Move cursor without moving display, if top or end of file is displaied.
    if line(vbl) == tob
      " Move cursor.
      if a:is_vmode
        execute "normal! \<ESC>"
        normal! gv
        execute 'normal! '.rest.a:cmd
      else
        execute 'normal! '.rest.a:cmd
      endif
      break
    endif

    " Calc cursor step count.
    let i += a:step
    let step = a:step
    if rest < step
      let step = rest
    endif

    " Move cursor.
    if a:is_vmode
      execute "normal! \<ESC>"
      normal! gv
      execute 'normal! '.step.a:cmd
    else
      execute 'normal! '.step.a:cmd
    endif

    " Move display.
    if !a:is_vmode || a:is_vmode && save_lazyredraw
      execute 'normal! '.step.move_disp_cmd
    endif

    " Redraw and Sleep.
    if i < a:wlcount
      " Redraw.
      if j >= a:skip_redraw_line_size
        let j = 0
        redraw
      else
        let j += 1
      endif
      " Sleep.
      if a:sleep_time_msec > 0
        execute sleep_cmd
      endif
    endif
  endwhile
  if a:is_vmode
    if !save_lazyredraw | set nolazyredraw | endif
  endif
endfunction
" }}}


" Global functions {{{
function! ac_smooth_scroll#scroll(cmd, windiv, sleep_time_msec, is_vmode)
  let elapsed_time = s:get_elapsed_time(a:cmd, a:windiv)

  " Check min time.
  if !a:is_vmode
        \ && elapsed_time >= 0
        \ && elapsed_time < g:ac_smooth_scroll_min_limit_msec
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

  " Do autocmd for Enter.
  call s:doautocmd_user('AcSmoothScrollEnter')

  " Disable highlight the screen line of the cursor,
  " because will make screen redrawing slower.
  let save_cul = &cul
  let save_vb = &vb
  let save_t_vb = &t_vb
  let save_rnu = &rnu

  if save_cul
    set nocul
  endif
  if !save_vb
    set vb
  endif
  set t_vb=

  if save_rnu == 1
    set nu
  endif

  call s:scroll(a:cmd, step, sleep_time_msec, skip_redraw_line_size, wlcount, a:is_vmode)

  " Restore changed settings.
  let &t_vb = save_t_vb
  if !save_vb | set novb | endif
  if save_cul | set cul | endif

  if save_rnu == 1 | set rnu | endif 

  " Do autocmd for Leave.
  call s:doautocmd_user('AcSmoothScrollLeave')

  let s:{a:cmd}{a:windiv}_timestamp_misec = reltime()
endfunction
" }}}


let &cpo = s:save_cpo
unlet s:save_cpo
