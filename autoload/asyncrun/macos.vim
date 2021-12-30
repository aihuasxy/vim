"======================================================================
"
" macos.vim - 
"
" Created by skywind on 2021/12/30
" Last Modified: 2021/12/30 15:52:58
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :


"----------------------------------------------------------------------
" script name
"----------------------------------------------------------------------
function! macos#script_name(name)
	let tmpname = fnamemodify(tempname(), ':h') . '/' . a:name
	return tmpname
endfunc


"----------------------------------------------------------------------
" write script 
"----------------------------------------------------------------------
function! macos#script_write(name, content)
	let tmpname = fnamemodify(tempname(), ':h') . '/' . a:name
	call writefile(a:content, tmpname)
	silent! call setfperm(tmpname, 'rwxrwxrws')
	return tmpname
endfunc


"----------------------------------------------------------------------
" return pause script
"----------------------------------------------------------------------
function! macos#pause_script()
	let lines = []
	if executable('bash')
		let pause = 'read -n1 -rsp "press any key to continue ..."'
		let lines += ['bash -c ''' . pause . '''']
	else
		let lines += ['echo "press enter to continue ..."']
		let lines += ['sh -c "read _tmp_"']
	endif
	return lines
endfunc


"----------------------------------------------------------------------
" write a scpt file 
"----------------------------------------------------------------------
function! macos#osascript(content, wait)
	let content = ['#! /usr/bin/osascript', '']
	let content += a:content
	let tmpname = macos#script_write('runner1.scpt', content)
	let cmd = '/usr/bin/osascript ' . shellescape(tmpname) 
	call system(cmd . ((a:wait)? '' : ' &'))
endfunc


"----------------------------------------------------------------------
" utils 
"----------------------------------------------------------------------
function! s:osascript(...) abort
	call system('osascript'.join(map(copy(a:000), '" -e ".shellescape(v:val)'), ''))
	return !v:shell_error
endfunction

function! s:escape(string) abort
	return '"'.escape(a:string, '"\').'"'
endfunction


"----------------------------------------------------------------------
" check version
"----------------------------------------------------------------------
function! asyncrun#macos#iterm_new_version() abort
  return s:osascript(
      \ 'on modernversion(version)',
      \   'set olddelimiters to AppleScript''s text item delimiters',
      \   'set AppleScript''s text item delimiters to "."',
      \   'set thearray to every text item of version',
      \   'set AppleScript''s text item delimiters to olddelimiters',
      \   'set major to item 1 of thearray',
      \   'set minor to item 2 of thearray',
      \   'set veryminor to item 3 of thearray',
      \   'if major < 2 then return false',
      \   'if major > 2 then return true',
      \   'if minor < 9 then return false',
      \   'if minor > 9 then return true',
      \   'if veryminor < 20140903 then return false',
      \   'return true',
      \ 'end modernversion',
      \ 'tell application "iTerm"',
      \   'if not my modernversion(version) then error',
      \ 'end tell')
endfunction


"----------------------------------------------------------------------
" spawn2
"----------------------------------------------------------------------
function! asyncrun#macos#iterm_spawn2(command, opts, activate) abort
	let script = asyncrun#utils#isolate(a:opts, [],
				\ asyncrun#utils#set_title(a:opts.title, a:opts.expanded), a:command)
	return s:osascript(
				\ 'if application "iTerm" is not running',
				\   'error',
				\ 'end if') && s:osascript(
				\ 'tell application "iTerm"',
				\   'tell the current terminal',
				\     'set oldsession to the current session',
				\     'tell (make new session)',
				\       'set name to ' . s:escape(a:opts.title),
				\       'set title to ' . s:escape(a:opts.expanded),
				\       'exec command ' . s:escape(script),
				\       a:request.background || !has('gui_running') ? 'select oldsession' : '',
				\     'end tell',
				\   'end tell',
				\   a:activate ? 'activate' : '',
				\ 'end tell')
endfunc


"----------------------------------------------------------------------
" spawn3 
"----------------------------------------------------------------------
function! asyncrun#macos#iterm_spawn3(command, opts, activate) abort
	let script = asyncrun#utils#isolate(a:opts, [],
				\ asyncrun#utils#set_title(a:opts.title, a:opts.expanded), a:command)
	return s:osascript(
				\ 'if application "iTerm" is not running',
				\   'error',
				\ 'end if') && s:osascript(
				\ 'tell application "iTerm"',
				\   'tell the current window',
				\     'set oldtab to the current tab',
				\     'set newtab to (create tab with default profile command ' . s:escape(script) . ')',
				\     'tell current session of newtab',
				\       'set name to ' . s:escape(a:opts.title),
				\       'set title to ' . s:escape(a:opts.expanded),
				\     'end tell',
				\     a:opts.background || !has('gui_running') ? 'select oldtab' : '',
				\   'end tell',
				\   a:activate ? 'activate' : '',
				\ 'end tell')
endfunc


"----------------------------------------------------------------------
" spawn new iterm
"----------------------------------------------------------------------
function! asyncrun#macos#iterm_spawn(command, opts)
	let opts = {}
	let opts.title = get(a:opts, 'title', 'AsyncRun')
	let opts.expanded = get(a:opts, 'expanded', 1)
	let opts.background = get(a:opts, 'background', 0)
	let opts.file = expand('%:t')
	let active = get(a:opts, 'active', 1)
	if asyncrun#macos#iterm_new_version()
		return asyncrun#macos#iterm_spawn3(a:command, opts, active)
	else
		return asyncrun#macos#iterm_spawn2(a:command, opts, active)
	endif
endfunc


"----------------------------------------------------------------------
" open system terminal
"----------------------------------------------------------------------
function! macos#open_system(title, script, profile)
	let content = ['#! /bin/sh']
	let content = ['clear']
	let content += [asyncrun#utils#set_title(a:title, 0)]
	let content += a:script
	let tmpname = macos#script_write('runner1.sh', content)
	let cmd = 'open -a Terminal ' . shellescape(tmpname)
	call system(cmd . ' &')
endfunc



