let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'wikipedia',
            \ 'description' : 'wikipedia search.',
            \ 'hooks' : {},
            \ }

function! s:unite_source.hooks.on_init(args, context)
    let input = get(a:args, 0, '')
    let input = input != '' ? input :
                \ unite#util#input('Searching keyword: ', '')
    call unite#print_source_message('Searching ...', 'wikipedia')
    let s:candidates = s:http_get(input)
    call unite#clear_message()
endfunction

function! s:unite_source.gather_candidates(args, context)
    if a:context.is_redraw
        let s:candidates = s:http_get(a:context.input)
    endif
    return s:candidates
endfunction

function! s:http_get(input)
    let param = {
                \ 'format' : 'json',
                \ 'action' : 'opensearch',
                \ 'search' : a:input
                \ }
    let res = webapi#http#get('http://en.wikipedia.org/w/api.php', param)
    if res.status != '200'
        echom 'http error code:'.res.status
        return []
    endif
    let content = webapi#json#decode(res.content)
    return map(content[1], 's:extract_entry(v:val)')
endfunction

function! s:extract_entry(word)
    return {
                \ 'word' : a:word,
                \ 'kind' : 'uri',
                \ 'action__uri' : 'http://en.wikipedia.com/wiki/'.substitute(a:word, '\s', '_', 'g'),
                \ 'source' : 'wikipedia'}
endfunction

function! unite#sources#wikipedia#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
