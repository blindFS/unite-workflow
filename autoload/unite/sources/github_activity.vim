let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []

function! unite#sources#github_activity#define()
    let sources = []
    for source in ['feed', 'event']
        let so = {
                    \ 'name' : 'github/'.source,
                    \ 'description' : 'Github '.source.'s of a certain user.',
                    \ 'hooks' : {
                    \   'on_syntax' : function('unite#libs#gh_event#on_syntax')
                    \ },
                    \ 'action_table' : {},
                    \ 'syntax' : 'uniteSource__github_event'
                    \ }

        let so.action_table.edit = {
                    \ 'description' : 'Edit with :Giedit.',
                    \ 'is_quit' : 1,
                    \ 'func' : function('unite#kinds#issue#edit')
                    \ }

        function! so.hooks.on_init(args, context)
            if exists('s:loaded')
                return
            endif
            let s:kind = split(a:context.source.name, '/')[1]
            call s:refresh(a:args)
            let s:loaded = 1
        endfunction

        function! so.hooks.on_close(args, context)
            call unite#libs#uri#clear_sign()
            if exists('s:loaded')
                unlet s:loaded
            endif
        endfunction

        function! so.hooks.on_post_filter(args, context)
            let s:context = a:context
            augroup workflow_icon
                autocmd! TextChanged,TextChangedI <buffer>
                            \ call unite#libs#uri#show_icon(0, s:context, s:context.candidates)
            augroup END
        endfunction

        function! so.gather_candidates(args, context)
            if a:context.is_redraw
                let s:kind = split(a:context.source.name, '/')[1]
                call s:refresh(a:args)
                let a:context.is_async = 1
            endif
            return s:candidates
        endfunction

        function! so.async_gather_candidates(args, context)
            if unite#libs#uri#show_icon(1, a:context, s:candidates)
                let a:context.is_async = 0
            endif
            return []
        endfunction

        call add(sources, so)
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
