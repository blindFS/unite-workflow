let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'v2ex',
            \ 'description' : 'Latest topics from http://www.v2ex.com',
            \ 'hooks' : {},
            \ 'syntax' : 'uniteSource__v2ex'
            \ }

function! unite#sources#v2ex#define()
    return s:unite_source
endfunction

function! s:unite_source.hooks.on_init(args, context)
    call s:refresh()
endfunction

function! s:unite_source.hooks.on_close(args, context)
    call unite#libs#uri#clear_sign()
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__v2ex_node /.\{-}\ze----/
                \ contained containedin=uniteSource__v2ex_title
    syntax match uniteSource__v2ex_title /.*/
                \ contained containedin=uniteSource__v2ex
                \ contains=uniteCandidateInputKeyword,uniteSource__v2ex_node
    highlight default link uniteSource__v2ex_node Constant
    highlight default link uniteSource__v2ex_title String
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
        call s:refresh()
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

function! s:refresh()
    call unite#print_source_message('Fetching latest feeds from the server ...', 'v2ex')
    let s:candidates = s:http_get()
    call unite#clear_message()
endfunction

function! s:http_get()
    let res = webapi#http#get('http://v2ex.com/api/topics/latest.json')
    if res.status != '200'
        echom 'http error code:'.res.status
        return []
    endif
    let content = webapi#json#decode(res.content)
    return map(content, 's:extract_entry(v:val)')
endfunction

function! s:extract_entry(dict)
    let icon_raw = a:dict.member.avatar_mini
    let icon_url = icon_raw =~ '^\/\/' ? '"http:'.icon_raw.'"' : '"'.icon_raw.'"'
    return {
                \ 'id' : a:dict.member.id,
                \ 'icon' : icon_url,
                \ 'action__uri' : a:dict.url,
                \ 'node' : a:dict.node.id,
                \ 'word' : a:dict.node.title.' ---- '.a:dict.title,
                \ 'kind' : 'uri',
                \ 'source' : 'v2ex'}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
