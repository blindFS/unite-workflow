let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name': 'v2ex',
            \ 'hooks' : {},
            \ 'action_table': {},
            \ 'syntax' : 'uniteSource__v2ex'
            \ }

function! s:unite_source.hooks.on_init(args, context)
    if exists('s:loaded')
        return
    endif
    call unite#print_source_message('Fetching latest feeds from the server ...', 'v2ex')
    let s:candidates = s:http_get()
    call unite#clear_message()
    let s:loaded = 1
endfunction

function! s:unite_source.hooks.on_close(args, context)
    unlet s:loaded
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

function! s:unite_source.gather_candidates(args, context)
    return s:candidates
endfunction

function! s:http_get()
    let res = webapi#http#get("http://v2ex.com/api/topics/latest.json")
    let content = webapi#json#decode(res.content)
    let entries = map(content, 's:extract_entry(v:val)')
    return entries
endfunction

function! s:extract_entry(dict)
    return {
                \ 'action__uri' : a:dict.url,
                \ 'node' : a:dict.node.id,
                \ 'word' : a:dict.node.title.' ---- '.a:dict.title,
                \ 'kind' : 'link',
                \ 'source' : 'v2ex'}
endfunction

function! unite#sources#v2ex#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
