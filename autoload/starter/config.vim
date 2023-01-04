" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" config.vim - 
"
" Created by skywind on 2022/09/07
" Last Modified: 2022/09/07 16:42:08
"
"======================================================================


"----------------------------------------------------------------------
" default config
"----------------------------------------------------------------------
let s:default_config = {
			\ 'icon_separator': '=>',
			\ 'icon_group': '+',
			\ 'icon_breadcrumb': '>',
			\ 'max_height': 20,
			\ 'min_height': 5,
			\ 'max_width': 60,
			\ 'min_width': 20,
			\ 'bracket': 0,
			\ 'padding': [2, 0, 2, 0],
			\ 'spacing': 3,
			\ 'vertical': 0,
			\ 'position': 'botright',
			\ 'splitmod': '',
			\ }


"----------------------------------------------------------------------
" position direction
"----------------------------------------------------------------------
let s:position_dict = {
			\ 'leftabove': 0, 'aboveleft': 0, 'lefta': 0, 'abo': 0,
			\ 'rightbelow': 1, 'belowright': 1, 'rightb': 1, 'bel': 1,
			\ 'topleft': 2, 'to': 2,
			\ 'botright': 3, 'bo': 3,
			\ }


"----------------------------------------------------------------------
" get config
"----------------------------------------------------------------------
function! starter#config#get(opts, key) abort
	if type(a:opts) == v:t_dict
		let opts = a:opts
	elseif type(a:opts) == v:t_none
		let opts = get(g:, 'quickui_starter', {})
	endif
	return get(opts, a:key, s:default_config[a:key])
endfunc


"----------------------------------------------------------------------
" internal help
"----------------------------------------------------------------------

" eval ${...}
function! s:keymap_eval(keymap) abort
	let keymap = a:keymap
	if type(keymap) == v:t_func
		let keymap = call(keymap, [])
	elseif type(keymap) == v:t_string
		let keymap = quickui#core#string_strip(keymap)
		if keymap =~ '\v^\$\{(.*)\}$'
			let t = strpart(keymap, 2, strlen(keymap) - 3)
			unlet keymap
			let keymap = eval(t)
		endif
	endif
	return keymap
endfunc

" read config
function! s:config(opts, key) abort
	return starter#config#get(a:opts, a:key)
endfunc

" ljust
function! starter#config#ljust(str, size) abort
	return a:str . repeat(' ', a:size - strwidth(a:str))
endfunc

" rjust
function! starter#config#rjust(str, size) abort
	return repeat(' ', a:size - strwidth(a:str)) . a:str
endfunc


"----------------------------------------------------------------------
" visit tree node
"----------------------------------------------------------------------
function! starter#config#visit(keymap, path) abort
	let keymap = a:keymap
	let path = a:path
	if type(keymap) == v:t_none || type(path) == v:t_none
		return v:none
	endif
	let index = 0
	while 1
		let keymap = s:keymap_eval(keymap)
		if index >= len(path)
			break
		endif
		let key = path[index]
		if !has_key(keymap, key)
			return v:none
		endif
		let keymap = keymap[key]
		let index += 1
	endwhile
	return keymap
endfunc


"----------------------------------------------------------------------
" compile keymap into ctx
"----------------------------------------------------------------------
function! starter#config#compile(keymap, opts) abort
	let keymap = a:keymap
	let opts = a:opts
	let ctx = {}
	let ctx.items = {}
	let ctx.keys = []
	let ctx.strwidth_key = 1
	let ctx.strwidth_txt = 8
	let icon_separator = s:config(a:opts, 'icon_separator')
	let icon_group = s:config(a:opts, 'icon_group')
	for key in keys(keymap)
		if key == '' || key == 'name'
			continue
		endif
		let key_code = starter#charname#get_key_code(key)
		if type(key_code) == v:t_none
			continue
		endif
		let ctx.keys += [key]
		let item = {}
		let item.key = key
		let item.code = key_code
		let item.label = starter#charname#get_key_label(key)
		let item.cmd = ''
		let item.text = ''
		let item.child = 0
		let ctx.items[key] = item
		let value = keymap[key]
		if type(value) == v:t_func
			unlet value
			let value = call(value, [])
		elseif type(value) == v:t_string
			let value = quickui#core#string_strip(value)
			if value =~ '\v^\$\{(.*)\}$'
				let t = strpart(value, 2, strlen(value) - 3)
				unlet value
				let value = eval(t)
			endif
		endif
		if type(value) == v:t_string
			let item.cmd = value
			let item.text = value
		elseif type(value) == v:t_list
			let item.cmd = (len(value) > 0)? value[0] : ''
			let item.text = (len(value) > 1)? value[1] : ''
		elseif type(value) == v:t_dict
			let item.child = 1
			let item.text = get(value, 'name', '...')
		endif
		if item.child
			if stridx(item.text, icon_group) != 0
				let item.text = icon_group . item.text
			endif
		endif
		if len(item.label) > ctx.strwidth_key
			let ctx.strwidth_key = strwidth(item.label)
		endif
		if len(item.text) >= ctx.strwidth_txt
			let ctx.strwidth_txt = strwidth(item.text)
		endif
	endfor
	let ctx.keys = starter#charname#sort(ctx.keys)
	let bracket = s:config(a:opts, 'bracket')
	if bracket
		if ctx.strwidth_key < 3
			let ctx.strwidth_key = 3
		endif
	endif
	let ctx.stride = ctx.strwidth_key + ctx.strwidth_txt 
	let ctx.stride = ctx.stride + 2 + strwidth(icon_separator)
	for key in ctx.keys
		let item = ctx.items[key]
		let label = item.label
		let text = item.text
		if strlen(label) == 1 && bracket
			let label = '[' . label . ']'
		endif
		let label = starter#config#rjust(label, ctx.strwidth_key)
		let text = starter#config#ljust(text, ctx.strwidth_txt)
		let item.content = printf('%s %s %s', label, icon_separator, text)
		let item.compact = printf('%s %s %s', label, icon_separator, item.text)
		let item.clength = strwidth(item.compact)
		let stride = strwidth(item.content)
		let ctx.stride = (ctx.stride >= stride)? ctx.stride : stride
	endfor
	let ctx.vertical = starter#config#get(a:opts, 'vertical')
	let ctx.position = starter#config#get(a:opts, 'position')
	let pos = get(s:position_dict, ctx.position, 3)
	if pos <= 1
		let ctx.position = (pos == 0)? 'leftabove' : 'rightbelow'
	else
		let ctx.position = (pos == 2)? 'topleft' : 'botright'
	endif
	return ctx
endfunc



