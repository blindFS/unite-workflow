let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []

function! unite#sources#github_activity#define()
    let sources = []
    for source in ['feed', 'event']
        let s:unite_source = {
                    \ 'name': 'github/'.source,
                    \ 'hooks' : {
                    \   'on_syntax' : function('unite#libs#gh_event#on_syntax')
                    \ },
                    \ 'syntax' : 'uniteSource__github_event'
                    \ }

        function! s:unite_source.hooks.on_init(args, context)
            if exists('s:loaded')
                return
            endif
            let s:kind = split(a:context.source.name, '/')[1]
            call s:refresh(a:args)
            let s:loaded = 1
        endfunction

        function! s:unite_source.hooks.on_close(args, context)
            execute 'sign unplace * buffer=' . bufnr('%')
            if exists('s:loaded')
                unlet s:loaded
            endif
        endfunction

        function! s:unite_source.hooks.on_post_filter(args, context)
            let s:context = a:context
            augroup workflow_icon
                autocmd! TextChanged,TextChangedI <buffer>
                            \ call unite#libs#uri#show_icon(0, s:context, s:context.candidates)
            augroup END
        endfunction

        function! s:unite_source.gather_candidates(args, context)
            if a:context.is_redraw
                let s:kind = split(a:context.source.name, '/')[1]
                call s:refresh(a:args)
                let a:context.is_async = 1
            endif
            return s:candidates
        endfunction

        function! s:unite_source.async_gather_candidates(args, context)
            if unite#libs#uri#show_icon(1, a:context, s:candidates)
                let a:context.is_async = 0
            endif
            return []
        endfunction

        call add(sources, s:unite_source)
    endfor

    return sources
endfunction

function! s:refresh(args)
    let target = get(a:args, 0, g:github_user)
    call unite#print_source_message('Fetching '.s:kind.'s of user '.
                \ target.' ...', 'github/'.s:kind)
    let s:candidates = unite#libs#gh_event#get_event(target, s:kind)
    call unite#clear_message()
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
