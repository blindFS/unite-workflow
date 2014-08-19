let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name': 'github/event',
            \ 'hooks' : {
            \   'on_syntax' : function('unite#libs#gh_event#on_syntax')
            \ },
            \ 'syntax' : 'uniteSource__github_event'
            \ }

function! s:unite_source.hooks.on_init(args, context)
    if exists('s:loaded')
        return
    endif
    let target = get(a:args, 0, g:github_user)
    call unite#print_source_message('Fetching events of user '.
                \ target.' ...', 'github/event')
    let s:candidates = unite#libs#gh_event#get_event(target, 'event')
    call unite#clear_message()
    let s:loaded = 1
endfunction

function! s:unite_source.hooks.on_close(args, context)
    unlet s:loaded
endfunction

function! s:unite_source.gather_candidates(args, context)
    return s:candidates
endfunction

function! unite#sources#github_event#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
