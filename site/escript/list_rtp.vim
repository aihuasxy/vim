tabnew
for name in split(&rtp, ',')
	let name = asclib#path#normalize(name)
	call append('$', [name])
endfor
exec "normal ggdd"
set nomodified

