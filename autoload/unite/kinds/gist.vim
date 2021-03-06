let s:save_cpo = &cpo
set cpo&vim

function! unite#kinds#gist#define()
    return s:kind
endfunction

let s:kind = {
            \ 'name' : 'gist',
            \ 'default_action' : 'start',
            \ 'action_table' : {},
            \ 'parents' : ['uri']
            \ }

let s:kind.action_table.edit = {
            \ 'description' : 'Edit the gist as a file.',
            \ 'is_selectable' : 1
            \ }

function! s:kind.action_table.edit.func(candidates)
    for candidate in a:candidates
        execute 'Gist '.candidate.action__id
    endfor
endfunction

function! unite#kinds#gist#on_syntax(args, context)
    syntax match uniteSource__gist_user /.*\ze\//
                \ contained containedin=uniteSource__gist
    syntax match uniteSource__gist_fname /\S\+\s\+\zs\S\+/
                \ contained containedin=uniteSource__gist
    highlight default link uniteSource__gist_user Constant
    highlight default link uniteSource__gist_fname Keyword
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
