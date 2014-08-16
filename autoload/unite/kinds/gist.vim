let s:save_cpo = &cpo
set cpo&vim

function! unite#kinds#gist#define()
    return s:kind
endfunction

let s:kind = {
            \ 'name' : 'gist',
            \ 'default_action' : 'open',
            \ 'action_table': {}
            \}

let s:kind.action_table.open = {
            \ 'description' : 'Open link in a browser.',
            \ 'is_quit' : 0
            \ }

function! s:kind.action_table.open.func(candidate)
    if has('unix')
        call system('xdg-open '.a:candidate.url.' &')
    elseif has('mac')
        call system('open '.a:candidate.url.' &')
    endif
endfunction


let s:kind.action_table.edit = {
            \ 'description' : 'Edit the gist as a file.',
            \ 'is_quit' : 1
            \ }

function! s:kind.action_table.edit.func(candidate)
    execute 'Gist '.a:candidate.id
endfunction

function! unite#kinds#gist#on_syntax(args, context)
    syntax match uniteSource__gist_user /.*\ze\// contained containedin=uniteSource__gist
    syntax match uniteSource__gist_fname /[ \t]\+.*$/ contained containedin=uniteSource__gist contains=uniteCandidateInputKeyword
    highlight default link uniteSource__gist_user Constant
    highlight default link uniteSource__gist_fname Keyword
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
