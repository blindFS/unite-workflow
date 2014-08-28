let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'reddit',
            \ 'description' : 'Latest topics from http://www.reddit.com',
            \ 'hooks' : {},
            \ 'action_table': {},
            \ 'syntax' : 'uniteSource__reddit'
            \ }

function! s:unite_source.hooks.on_init(args, context)
    if exists('s:loaded')
        return
    endif
    call s:refresh(a:args)
    let s:loaded = 1
endfunction

function! s:unite_source.hooks.on_close(args, context)
    if exists('s:loaded')
        unlet s:loaded
    endif
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__reddit_subreddit /.\{-}\ze----/
                \ contained containedin=uniteSource__reddit_title
    syntax match uniteSource__reddit_title /.*/
                \ contained containedin=uniteSource__reddit
                \ contains=uniteCandidateInputKeyword,uniteSource__reddit_subreddit
    highlight default link uniteSource__reddit_subreddit Constant
    highlight default link uniteSource__reddit_title String
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
    return map(content.data.children, 's:extract_entry(v:val)')
endfunction

function! s:refresh(args)
    let subreddit = get(a:args, 0, '')
    let url_pre = 'http://www.reddit.com'
    call unite#print_source_message('Fetching feeds from the server ...',
                \ s:unite_source.name)
    if subreddit != ''
        let url = url_pre.'/r/'.subreddit.'/hot.json'
    else
        let url = get(g:, 'unite#workflow#reddit#front', url_pre.'/hot.json')
    endif
    let s:candidates = s:http_get(url)
    call unite#clear_message()
endfunction

function! s:extract_entry(dict)
    return {
                \ 'word' : a:dict.data.subreddit.' ---- '.a:dict.data.title,
                \ 'action__uri' : 'http://www.reddit.com/'.a:dict.data.permalink,
                \ 'kind' : 'uri',
                \ 'source' : 'reddit'
                \ }

endfunction

function! unite#sources#reddit#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
