let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'turing',
            \ 'description' : 'Turing robot',
            \ 'action_table' : {},
            \ 'hooks' : {},
            \ }

let s:unite_source.action_table.insert = {
            \ 'description' : 'Reply to the bot.',
            \ 'is_quit' : 1
            \ }

function! s:unite_source.action_table.insert.func(candidate)
    call unite#start(['turing'])
endfunction


function! s:unite_source.hooks.on_init(args, context)
    let input = get(a:args, 0, '')
    let input = input != '' ? input :
                \ unite#util#input('Conversation: ', '')
    call s:refresh(input)
endfunction

function! s:unite_source.gather_candidates(args, context)
    return s:candidates
endfunction

function! s:http_get(input)
    let param = {
                \ 'key' : '47ab88116e493791a0d4850de55b6ded',
                \ 'info' : a:input
                \ }
    let res = webapi#http#get('http://www.tuling123.com/openapi/api', param)
    if res.status != '200'
        echom 'http error code:'.res.status
        return []
    endif
    let content = webapi#json#decode(res.content)
    if has_key(content, 'list')
        return map(content.list, 's:extract_entry(v:val)')
    endif
    let result = {
                \ 'word' : content.text,
                \ 'kind' : 'word',
                \ 'is_multiline' : 1,
                \ 'source' : 'turing'
                \ }
    if has_key(content, 'url')
        let result.word .= ' 🔗 '
        let result.kind = 'uri'
        let result.action__uri = content.url
    endif
    return [result]
endfunction

function! s:extract_entry(dict)
    return {
                \ 'word' : get(a:dict, 'article', get(a:dict, 'name', 'unknown')),
                \ 'kind' : 'uri',
                \ 'action__uri' : get(a:dict, 'detailurl', 'http://www.tuling123.com'),
                \ 'source' : 'turing'
                \ }
endfunction

function! s:refresh(input)
    call unite#print_source_message('Getting response ...', 'turing')
    let s:candidates = s:http_get(a:input)
    call unite#clear_message()
endfunction

function! unite#sources#turing#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

