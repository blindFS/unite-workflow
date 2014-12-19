let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'zhihu',
            \ 'description' : '知乎日报',
            \ 'hooks' : {},
            \ }

function! s:unite_source.hooks.on_init(args, context)
    call s:refresh(a:args)
endfunction

function! s:unite_source.gather_candidates(args, context)
    if a:context.is_redraw
        call s:refresh(a:args)
    endif
    return s:candidates
endfunction

function! s:http_get(url)
    let res = webapi#http#get(a:url)
    if res.status != '200'
        echom 'http error code:'.res.status
        return []
    endif
    let content = webapi#json#decode(res.content)
    return map(content.stories, 's:extract_entry(v:val)')
endfunction

function! s:refresh(args)
    call unite#print_source_message('获取日报 ...',
                \ s:unite_source.name)
    let s:candidates = s:http_get('http://news-at.zhihu.com/api/3/news/latest')
    call unite#clear_message()
endfunction

function! s:extract_entry(dict)
    return {
                \ 'word' : a:dict.title,
                \ 'action__uri' : 'http://daily.zhihu.com/story/'.a:dict.id,
                \ 'kind' : 'uri',
                \ 'source' : 'zhihu'
                \ }

endfunction

function! unite#sources#zhihu#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
