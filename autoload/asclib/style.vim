"======================================================================
"
" style.vim - 
"
" Created by skywind on 2022/11/20
" Last Modified: 2022/11/20 22:38:14
"
"======================================================================

function! asclib#style#remove_style(what)
	let need = ['underline', 'undercurl', 'reverse', 'inverse', 'italic', 'standout', 'bold']
	let hid = 1
	call filter(need, 'v:val != a:what')
	while 1
		let hln = synIDattr(hid, 'name')
		if !hlexists(hln) | break | endif
		if hid == synIDtrans(hid) 
			let change = ''
			for mode in ['gui', 'term', 'cterm']
				if synIDattr(hid, a:what, mode)
					let atr = deepcopy(need)
					call filter(atr, 'synIDattr(hid, v:val, mode)')
					let result = empty(atr) ? 'NONE' : join(atr, ',')
					let change .= printf(' %s=%s', mode, result)
				endif
			endfor
			if change != ''
				exec 'highlight ' . hln . ' ' . change
			endif
		endif
		let hid += 1
	endwhile
endfunc


