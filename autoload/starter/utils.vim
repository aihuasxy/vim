" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" utils.vim - utils
"
" Created by skywind on 2022/12/24
" Last Modified: 2022/12/24 03:38:40
"
"======================================================================


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:bid = -1
let s:previous_wid = -1
let s:working_wid = -1


"----------------------------------------------------------------------
" internal save view
"----------------------------------------------------------------------
function! s:save_view(mode)
	if a:mode == 0
		let w:starter_save = winsaveview()
	else
		if exists('w:starter_save')
			if get(b:, 'starter_keep', 0) == 0
				call winrestview(w:starter_save)
			endif
			unlet w:starter_save
		endif
	endif
endfunc


"----------------------------------------------------------------------
" save view
"----------------------------------------------------------------------
function! starter#utils#save_view() abort
	let winid = winnr()
	keepalt noautocmd windo call s:save_view(0)
	keepalt noautocmd silent! exec printf('%dwincmd w', winid)
endfunc


"----------------------------------------------------------------------
" restore view
"----------------------------------------------------------------------
function! starter#utils#restore_view() abort
	let winid = winnr()
	keepalt noautocmd windo call s:save_view(1)
	keepalt noautocmd silent! exec printf('%dwincmd w', winid)
endfunc


"----------------------------------------------------------------------
" create a new buffer
"----------------------------------------------------------------------
function! starter#utils#create_buffer() abort
	if has('nvim') == 0
		let bid = bufadd('')
		call bufload(bid)
		call setbufvar(bid, '&buflisted', 0)
		call setbufvar(bid, '&bufhidden', 'hide')
	else
		let bid = nvim_create_buf(v:false, v:true)
	endif
	call setbufvar(bid, '&modifiable', 1)
	call deletebufline(bid, 1, '$')
	call setbufvar(bid, '&modified', 0)
	call setbufvar(bid, '&filetype', '')
	return bid
endfunc


"----------------------------------------------------------------------
" update buffer content
"----------------------------------------------------------------------
function! starter#utils#update_buffer(bid, textlist) abort
	if type(a:textlist) == v:t_list
		let textlist = a:textlist
	else
		let textlist = split('' . a:textlist, '\n', 1)
	endif
	let old = getbufvar(a:bid, '&modifiable', 0)
	call setbufvar(a:bid, '&modifiable', 1)
	call deletebufline(a:bid, 1, '$')
	call setbufline(a:bid, 1, textlist)
	call setbufvar(a:bid, '&modified', old)
endfunc


"----------------------------------------------------------------------
" open window
"----------------------------------------------------------------------
function! starter#utils#window_open(opts) abort
	let opts = a:opts
	let vertical = starter#config#get(opts, 'vertical')
	let position = starter#config#get(opts, 'position')
	let min_height = starter#config#get(opts, 'min_height')
	let min_width = starter#config#get(opts, 'min_width')
	let s:previous_wid = winnr()
	call starter#utils#save_view()
	if vertical == 0
		exec printf('%s %dsplit', position, min_height)
	else
		exec printf('%s %dvsplit', position, min_width)
	endif
	call starter#utils#restore_view()
	let s:working_wid = winnr()
	if s:bid < 0
		let s:bid = starter#utils#create_buffer()
	endif
	let bid = s:bid
	exec 'b ' . bid
	setlocal bt=nofile nobuflisted nomodifiable
	setlocal nowrap nonumber nolist nocursorline nocursorcolumn noswapfile
	if exists('+cursorlineopt')
		setlocal cursorlineopt=both
	endif
	if has('signs') && has('patch-7.4.2210')
		setlocal signcolumn=no 
	endif
	if has('spell')
		setlocal nospell
	endif
	if has('folding')
		setlocal fdc=0
	endif
	call starter#utils#update_buffer(bid, [])
endfunc


"----------------------------------------------------------------------
" window close
"----------------------------------------------------------------------
function! starter#utils#window_close() abort
	if s:working_wid > 0
		call starter#utils#save_view()
		exec printf('%dclose', s:working_wid)
		call starter#utils#restore_view()
		let s:working_wid = -1
		if s:previous_wid > 0
			exec printf('%dwincmd w', s:previous_wid)
			let s:previous_wid = -1
		endif
	endif
endfunc


"----------------------------------------------------------------------
" resize window
"----------------------------------------------------------------------
function! starter#utils#window_resize(wid, width, height) abort
	let wid = (a:wid == 0)? winnr() : a:wid
	call starter#utils#save_view()
	if a:width >= 0
		exec printf('vert %dresize %d', wid, a:width)
	endif
	if a:height >= 0
		exec printf('%dresize %d', wid, a:height)
	endif
	call starter#utils#restore_view()
endfunc


"----------------------------------------------------------------------
" update window content
"----------------------------------------------------------------------
function! starter#utils#window_update(textline) abort
	if s:bid > 0
		call starter#utils#update_buffer(s:bid, a:textline)
	endif
endfunc


"----------------------------------------------------------------------
" execute in window
"----------------------------------------------------------------------
function! starter#utils#window_execute(command) abort
	if type(a:command) == type([])
		let command = join(a:command, "\n")
	elseif type(a:command) == type('')
		let command = a:command
	else
		let command = a:command
	endif
	if s:working_wid > 0
		let wid = winnr()
		noautocmd exec printf('%dwincmd w', s:working_wid)
		exec command
		noautocmd exec printf('%dwincmd w', wid)
	endif
endfunc


