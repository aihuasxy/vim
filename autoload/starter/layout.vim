" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" layout.vim - window layout
"
" Created by skywind on 2022/11/25
" Last Modified: 2022/11/25 20:02:09
"
"======================================================================


"----------------------------------------------------------------------
" horizon
"----------------------------------------------------------------------
function! s:layout_horizon(ctx, opts) abort
	let ctx = a:ctx
	let padding = starter#config#get(a:opts, 'padding')
	let spacing = starter#config#get(a:opts, 'spacing')
	let ctx.cx = a:ctx.wincx - (padding[0] + padding[2])
	if ctx.cx <= ctx.stride
		let ctx.ncols = 1
	else
		" Ax + B(x-1) = y  -->  (A+B)x = y+B  --> x = (y+B)/(A+B)
		let ctx.ncols = (ctx.cx + spacing) / (spacing + ctx.stride)
	endif
	if type(ctx.ncols) == 5
		let ctx.ncols = float2nr(ctx.ncols)
	endif
	let ctx.ncols = (ctx.ncols < 1)? 1 : ctx.ncols
	let nitems = len(ctx.items)
	let ctx.nrows = (nitems + ctx.ncols - 1) / ctx.ncols
	if type(ctx.nrows) == 5
		let ctx.nrows = float2nr(ctx.nrows)
	endif
	let min_height = starter#config#get(a:opts, 'min_height')
	let max_height = starter#config#get(a:opts, 'max_height')
	let padding = starter#config#get(a:opts, 'padding')
	let ypad = padding[1] + padding[3]
	let min_height -= ypad
	let max_height -= ypad
	let min_height = (min_height < 1)? 1 : min_height
	let max_height = (max_height < 1)? 1 : max_height
	let ctx.pg_count = (ctx.nrows + max_height - 1) / max_height
	if type(ctx.pg_count) == 5
		let ctx.pg_count = float2nr(ctx.pg_count)
	endif
	let ctx.pg_height = ctx.nrows
	let ctx.pg_height = (max_height < ctx.pg_height)? max_height : ctx.pg_height
	let ctx.pg_height = (min_height > ctx.pg_height)? min_height : ctx.pg_height
	let ctx.pg_size = ctx.pg_height * ctx.ncols
	let ctx.pages = []
endfunc


"----------------------------------------------------------------------
" vertical
"----------------------------------------------------------------------
function! s:layout_vertical(ctx, opts) abort
	let a:ctx.wincy = winheight(0)
endfunc


"----------------------------------------------------------------------
" layout init
"----------------------------------------------------------------------
function! starter#layout#init(ctx, opts, hspace, vspace) abort
	let a:ctx.wincx = a:hspace
	let a:ctx.wincy = a:vspace
	if a:ctx.vertical == 0
		call s:layout_horizon(a:ctx, a:opts)
	else
		call s:layout_vertical(a:ctx, a:opts)
	endif
endfunc



"----------------------------------------------------------------------
" fill a column
"----------------------------------------------------------------------
function! starter#layout#fill_column(ctx, opts, start, size, minwidth) abort
	let ctx = a:ctx
	let column = []
	let index = a:start
	let endup = index + a:size
	let endup = (endup < len(ctx.keys))? endup : len(ctx.keys)
	let csize = 0
	while index < endup
		let item = ctx.items[ctx.keys[index]]
		let column += [item.compact]
		let index += 1
	endwhile
	for text in column
		let width = strwidth(text)
		let csize = (width > csize)? width : csize
	endfor
	let csize = (csize < a:minwidth)? a:minwidth : csize
	let index = 0
	while index < len(column)
		let text = column[index]
		let width = strwidth(text)
		if width < csize
			let column[index] = text . repeat(' ', csize - width)
		endif
		let index += 1
	endwhile
	return column
endfunc


"----------------------------------------------------------------------
" fill to necessary size
"----------------------------------------------------------------------
function! starter#layout#just_column(column, size)
	let newcolumn = []
	if len(a:column) >= a:size
		return a:column
	endif
	let width = 0
	if len(a:column) > 0
		let width = strwidth(a:column[0])
	endif
	let text = repeat(' ', width)
	return a:column + repeat([text], a:size - len(a:column))
endfunc


"----------------------------------------------------------------------
" fill a page
"----------------------------------------------------------------------
function! starter#layout#fill_page(ctx, opts, start, size, winheight) abort
	let ctx = a:ctx
	let winheight = a:winheight
	let page = {}
	let columns = []
	let cowidth = []
	let ncols = (a:size + winheight - 1) / winheight
	let minwidth = 0
	" let minwidth = ctx.stride
	if type(ncols) == 5
		let ncols = float2nr(ncols)
	endif
	for index in range(ncols)
		let start = a:start + winheight * index
		let endup = start + winheight
		if endup > a:start + a:size
			let endup = a:start + a:size
		endif
		let require = endup - start
		let column = starter#layout#fill_column(ctx, a:opts, start, require, minwidth)
		let column = starter#layout#just_column(column, winheight)
		let width = 0
		if len(column) > 0
			let width = strwidth(column[0])
		endif
		let columns += [column]
		let cowidth += [width]
	endfor
	let padding = starter#config#get(a:opts, 'padding')
	let spacing = starter#config#get(a:opts, 'spacing')
	let space1 = repeat(' ', padding[0])
	let space2 = repeat(' ', padding[2])
	let space3 = repeat(' ', spacing)
	let content = []
	let content += repeat([''], padding[1])
	for y in range(winheight)
		let parts = repeat([''], ncols)
		for x in range(ncols)
			let t = columns[x][y]
			let parts[x] = t
		endfor
		let t = space1 . join(parts, space3)
		let content += [t]
	endfor
	let content += repeat([''], padding[3])
	let page.content = content
	return page
endfunc



