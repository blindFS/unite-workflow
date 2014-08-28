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
            \ 'is_quit' : 1,
            \ 'func' : function('unite#kinds#issue#edit')
            \ }

let s:kind.action_table.add = {
            \ 'description' : 'Create a new issue.',
            \ 'is_quit' : 1
            \ }

function! s:kind.action_table.add.func(candidate)
    if !exists(':Giadd')
        echom 'You need to load jaxbot/github-issues.vim first.'
        return
    endif
    Giadd
endfunction

function! unite#kinds#issue#edit(candidate)
    let number = matchstr(a:candidate.action__uri, 'issues/\zs\d\+$')
    if number == ''
        return
    endif
    if !exists(':Giedit')
        echom 'You need to load jaxbot/github-issues.vim first.'
        return
    endif
    echo 'Opening #'.number.' with Giedit ...'
    execute 'Giedit '.number.' '.a:candidate.action__repo
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
