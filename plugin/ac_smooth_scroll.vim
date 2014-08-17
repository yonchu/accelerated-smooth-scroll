scriptencoding utf-8
if exists('g:loaded_ac_smooth_scroll')
  finish
endif
let g:loaded_ac_smooth_scroll = 1

let s:save_cpo = &cpo
set cpo&vim


" Global variables {{{
let g:ac_smooth_scroll_enable_accelerating = get(g:, 'ac_smooth_scroll_enable_accelerating', 1)

let g:ac_smooth_scroll_disable_relativenumber = get(g:, 'g:ac_smooth_scroll_disable_relativenumber', 1)

let g:ac_smooth_scroll_du_sleep_time_msec = get(g:, 'ac_smooth_scroll_du_sleep_time_msec', 10)
let g:ac_smooth_scroll_fb_sleep_time_msec = get(g:, 'ac_smooth_scroll_fb_sleep_time_msec', 10)
let g:ac_smooth_scroll_skip_redraw_line_size = get(g:, 'ac_smooth_scroll_skip_redraw_line_size', 0)

let g:ac_smooth_scroll_min_limit_msec = get(g:, 'ac_smooth_scroll_min_limit_msec', 50)
let g:ac_smooth_scroll_max_limit_msec = get(g:, 'ac_smooth_scroll_max_limit_msec', 300)

if !exists('*AcSmoothScrollCalcStep')
  function! AcSmoothScrollCalcStep(key_count, wlcount)
    if a:key_count > a:wlcount / 2
      return a:wlcount
    endif
    return a:key_count
  endfunction
endif

if !exists('*AcSmoothScrollCalcSleepTimeMsec')
  function! AcSmoothScrollCalcSleepTimeMsec(key_count, sleep_time_msec)
    return  a:sleep_time_msec - (a:key_count - 1)
  endfunction
endif

if !exists('*AcSmoothScrollCalcSkipRedrawLineSize')
  function! AcSmoothScrollCalcSkipRedrawLineSize(key_count, skip_redraw_line_size)
    " return  a:skip_redraw_line_size + (a:key_count - 1)
    return a:skip_redraw_line_size
  endfunction
endif
" }}}


" Interfaces {{{

nnoremap <silent> <Plug>(ac-smooth-scroll-c-d)
     \ :<C-u>call ac_smooth_scroll#scroll('j', 2, g:ac_smooth_scroll_du_sleep_time_msec, 0)<cr>
nnoremap <silent> <Plug>(ac-smooth-scroll-c-u)
     \ :<C-u>call ac_smooth_scroll#scroll('k', 2, g:ac_smooth_scroll_du_sleep_time_msec, 0)<cr>

nnoremap <silent> <Plug>(ac-smooth-scroll-c-f)
     \ :<C-u>call ac_smooth_scroll#scroll('j', 1, g:ac_smooth_scroll_fb_sleep_time_msec, 0)<cr>
nnoremap <silent> <Plug>(ac-smooth-scroll-c-b)
     \ :<C-u>call ac_smooth_scroll#scroll('k', 1, g:ac_smooth_scroll_fb_sleep_time_msec, 0)<cr>

xnoremap <silent> <Plug>(ac-smooth-scroll-c-d_v)
     \ :<C-u>call ac_smooth_scroll#scroll('j', 2, g:ac_smooth_scroll_du_sleep_time_msec, 1)<cr>
xnoremap <silent> <Plug>(ac-smooth-scroll-c-u_v)
     \ :<C-u>call ac_smooth_scroll#scroll('k', 2, g:ac_smooth_scroll_du_sleep_time_msec, 1)<cr>

xnoremap <silent> <Plug>(ac-smooth-scroll-c-f_v)
     \ :<C-u>call ac_smooth_scroll#scroll('j', 1, g:ac_smooth_scroll_fb_sleep_time_msec, 1)<cr>
xnoremap <silent> <Plug>(ac-smooth-scroll-c-b_v)
     \ :<C-u>call ac_smooth_scroll#scroll('k', 1, g:ac_smooth_scroll_fb_sleep_time_msec, 1)<cr>
" }}}


" Default mappings {{{
if !get(g:, 'ac_smooth_scroll_no_default_key_mappings', 0)
  nmap <silent> <C-d> <Plug>(ac-smooth-scroll-c-d)
  nmap <silent> <C-u> <Plug>(ac-smooth-scroll-c-u)
  nmap <silent> <C-f> <Plug>(ac-smooth-scroll-c-f)
  nmap <silent> <C-b> <Plug>(ac-smooth-scroll-c-b)
  if get(g:, 'ac_smooth_scroll_visualmode_key_mappings', 1)
    xmap <silent> <C-d> <Plug>(ac-smooth-scroll-c-d_v)
    xmap <silent> <C-u> <Plug>(ac-smooth-scroll-c-u_v)
    xmap <silent> <C-f> <Plug>(ac-smooth-scroll-c-f_v)
    xmap <silent> <C-b> <Plug>(ac-smooth-scroll-c-b_v)
  endif
endif
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo
