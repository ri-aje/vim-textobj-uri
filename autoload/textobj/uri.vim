" uri.vim:	Textobjects for dealing with URIs
" Last Modified: Sat 14. Dec 2013 12:43:29 +0100 CET
" Author:		Jan Christoph Ebersbach <jceb@e-jc.de>
" Copyright:    2013 Jan Christoph Ebersbach
" License:		MIT LICENSE, see LICENSE file

function! s:extract_uri(trailing_whitespace)
	let orig_pos = getpos('.')
	let positioning_patterns = copy(g:textobj_uri_positioning_patterns)
	for ft in split(&ft, '\.')
		if exists('g:textobj_uri_positioning_patterns_'.ft)
			call extend(positioning_patterns, eval('g:textobj_uri_positioning_patterns_'.ft))
		endif
	endfor
	for ppattern in positioning_patterns
		let nozs_ppattern = substitute(ppattern, '\\zs', '', 'g')
		call setpos('.', orig_pos)
		if search(nozs_ppattern, 'ceW', orig_pos[1], g:textobj_uri_search_timeout) == 0
			call setpos('.', orig_pos)
			continue
		endif
		let end_pos = getpos('.')

		if search(nozs_ppattern, 'bcW', orig_pos[1], g:textobj_uri_search_timeout) == 0
			call setpos('.', orig_pos)
			continue
		endif
		let start_pos = getpos('.')

		if search(ppattern, 'cW', orig_pos[1], g:textobj_uri_search_timeout) == 0
			call setpos('.', orig_pos)
			continue
		endif

		let uri_pos = getpos('.')
		if start_pos[2] > orig_pos[2] || end_pos[2] < orig_pos[2] || start_pos[2] > uri_pos[2] || end_pos[2] < uri_pos[2]
			call setpos('.', orig_pos)
			continue
		endif
		let orig_pos = uri_pos
		break
	endfor
	for pattern in keys(g:textobj_uri_patterns)
		call setpos('.', orig_pos)
		let tmp_pattern = pattern
		if a:trailing_whitespace
			let tmp_pattern = pattern . '\s*'
		endif
		if search(tmp_pattern, 'ceW', orig_pos[1], g:textobj_uri_search_timeout) == 0
			call setpos('.', orig_pos)
			continue
		endif
		let end_pos = getpos('.')

		if search(tmp_pattern, 'bcW', orig_pos[1], g:textobj_uri_search_timeout) == 0
			call setpos('.', orig_pos)
			continue
		endif
		let start_pos = getpos('.')
		if start_pos[2] > orig_pos[2] || end_pos[2] < orig_pos[2]
			" cursor is not within the pattern
			call setpos('.', orig_pos)
			continue
		endif
		return [pattern, 'v', start_pos, end_pos]
	endfor
endfunction

function! textobj#uri#selecturi_a()
	let res = s:extract_uri(1)
	if len(res) == 4
		return res[1:]
	endif
endfunction

function! textobj#uri#selecturi_i()
	let res = s:extract_uri(0)
	if len(res) == 4
		return res[1:]
	endif
endfunction

function! textobj#uri#add_pattern(bang, pattern, ...)
	if a:bang
		let g:textobj_uri_patterns = {}
	endif
	if a:0
		let g:textobj_uri_patterns[a:pattern] = a:000[0]
	else
		let g:textobj_uri_patterns[a:pattern] = ''
	endif
endfunction

function! textobj#uri#add_positioning_pattern(bang, ppattern, ...)
	if a:bang
		if a:0
			for ft in a:000
				exec 'let g:textobj_uri_positioning_patterns_'.ft.' = []'
			endfor
		else
			let g:textobj_uri_positioning_patterns = []
		endif
	endif
	if a:0
		for ft in a:000
			if ! exists('g:textobj_uri_positioning_patterns_'.ft)
				exec ':let g:textobj_uri_positioning_patterns_'.ft.' = []'
			endif
			call add(eval('g:textobj_uri_positioning_patterns_'.ft), a:ppattern)
		endfor
	else
		call add(g:textobj_uri_positioning_patterns, a:ppattern)
	endif
endfunction

function! textobj#uri#open_uri()
	let res = s:extract_uri(0)
	let uri = ''
	if len(res) == 4
		let uri = getline('.')[res[2][2]-1:res[3][2]-1]
		let handler = substitute(g:textobj_uri_patterns[res[0]], '%s', uri, 'g')
		if len(handler)
			if handler[0] == ':'
				exec handler
			else
				exec 'normal' handler
			endif
		else
			throw "No handler specified"
		endif
	endif
	return uri
endfunction