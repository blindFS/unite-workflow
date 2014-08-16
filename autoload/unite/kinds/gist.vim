let s:save_cpo = &cpo
set cpo&vim

function! unite#kinds#gist#define()
    return s:kind
endfunction

let s:kind = {
            \ 'name' : 'gist',
            \ 'default_action' : 'edit',
            \ 'action_table' : {},
            \ 'parents' : ['uri']
            \ }

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
