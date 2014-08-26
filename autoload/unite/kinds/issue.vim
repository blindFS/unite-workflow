let s:save_cpo = &cpo
set cpo&vim

function! unite#kinds#issue#define()
    return s:kind
endfunction

let s:kind = {
            \ 'name' : 'issue',
            \ 'default_action' : 'start',
            \ 'action_table' : {},
            \ 'parents' : ['uri']
            \ }

let s:kind.action_table.edit = {
            \ 'description' : 'View the issue.',
            \ 'is_quit' : 1
            \ }

function! s:kind.action_table.edit.func(candidate)
    if !exists(':Giedit')
        echoerr 'You need to load jaxbot/github-issues.vim first.'
        return
    endif
    echo 'Opening #'.a:candidate.action__number.' with Giedit ...'
    execute 'Giedit '.a:candidate.action__number
    redraw
endfunction

let s:kind.action_table.add = {
            \ 'description' : 'Create a new issue.',
            \ 'is_quit' : 1
            \ }

function! s:kind.action_table.add.func(candidate)
    if !exists(':Giadd')
        echoerr 'You need to load jaxbot/github-issues.vim first.'
        return
    endif
    Giadd
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
