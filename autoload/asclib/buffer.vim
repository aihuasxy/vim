" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" buffer.vim - 
"
" Created by skywind on 2022/10/01
" Last Modified: 2022/10/01 22:45:06
"
"======================================================================


"----------------------------------------------------------------------
" alloc a new buffer
"----------------------------------------------------------------------
function! asclib#buffer#alloc()
	if !exists('s:buffer_array')
		let s:buffer_array = {}
	endif
	let index = len(s:buffer_array) - 1
	if index >= 0
		let bid = s:buffer_array[index]
		unlet s:buffer_array[index]
	else
		if has('nvim') == 0
			let bid = bufadd('')
			call bufload(bid)
			call setbufvar(bid, '&buflisted', 0)
			call setbufvar(bid, '&bufhidden', 'hide')
		else
			let bid = nvim_create_buf(v:false, v:true)
		endif
	endif
	call setbufvar(bid, '&modifiable', 1)
	call deletebufline(bid, 1, '$')
	call setbufvar(bid, '&modified', 0)
	call setbufvar(bid, '&filetype', '')
	return bid
endfunc


"----------------------------------------------------------------------
" free a buffer
"----------------------------------------------------------------------
function! asclib#buffer#release(bid)
	if !exists('s:buffer_array')
		let s:buffer_array = {}
	endif
	let index = len(s:buffer_array)
	let s:buffer_array[index] = a:bid
	call setbufvar(a:bid, '&modifiable', 1)
	call deletebufline(a:bid, 1, '$')
	call setbufvar(a:bid, '&modified', 0)
endfunc


"----------------------------------------------------------------------
" update buffer content
"----------------------------------------------------------------------
function! asclib#buffer#update(bid, textlist)
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
" clear buffer content
"----------------------------------------------------------------------
function! asclib#buffer#clear(bid)
	call asclib#buffer#update(a:bid, [])
endfunc


"----------------------------------------------------------------------
" get named buffer
"----------------------------------------------------------------------
function! asclib#buffer#named(name)
	if !exists('s:buffer_cache')
		let s:buffer_cache = {}
	endif
	if a:name != ''
		let bid = get(s:buffer_cache, a:name, -1)
	else
		let bid = -1
	endif
	if bid < 0
		let bid = asclib#buffer#alloc()
		if a:name != ''
			let s:buffer_cache[a:name] = bid
		endif
	endif
	return bid
endfunc


"----------------------------------------------------------------------
" list buffer bid
"----------------------------------------------------------------------
function! asclib#buffer#list()
    let l:ls_cli = get(g:, 'asclib#buffer#list_cli', 'ls t')
    redir => buflist
    silent execute l:ls_cli
    redir END
    let bids = []
    for curline in split(buflist, '\n')
        if curline =~ '^\s*\d\+'
            let bid = str2nr(matchstr(curline, '^\s*\zs\d\+'))
            let bids += [bid]
        endif
    endfor
    return bids
endfunc



