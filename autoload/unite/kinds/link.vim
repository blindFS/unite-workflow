let s:save_cpo = &cpo
set cpo&vim

function! unite#kinds#link#define()
    return s:kind
endfunction

let s:kind = {
            \ 'name' : 'link',
            \ 'default_action' : 'start',
            \ 'action_table' : {},
            \ 'parents' : ['uri']
            \ }

let s:kind.action_table.start = {
            \ 'description' : 'open uri by browser',
            \ 'is_selectable' : 1,
            \ 'is_quit' : 0
            \ }

function! s:kind.action_table.start.func(candidates)
    call unite#take_action('start', a:candidates)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
