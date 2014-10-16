let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:url_pre = 'http://music.163.com/'
let s:unite_source = {
            \ 'name' : 'music163',
            \ 'description' : '网易云音乐搜索',
            \ 'hooks' : {},
            \ 'syntax' : 'uniteSource__music163'
            \ }

function! s:unite_source.hooks.on_init(args, context)
    let input = get(a:args, 0, '')
    let input = input != '' ? input :
                \ unite#util#input('Search for songs: ', '')
    call s:refresh(input)
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__music163_artists /.*\ze\s\+--/
                \ contained containedin=uniteSource__music163
    syntax match uniteSource__music163_album /【.\{-}】/
                \ contained containedin=uniteSource__music163
                \ contained containedin=uniteSource__music163
    highlight default link uniteSource__music163_artists Constant
    highlight default link uniteSource__music163_album String
endfunction

function! s:unite_source.gather_candidates(args, context)
    if a:context.is_redraw
        if a:context.input != ''
            let input = a:context.input
            call s:refresh(input)
        endif
    endif
    return s:candidates
endfunction

function! s:http_get(input)
    let param = {
                \ 's' : a:input,
                \ 'limit' : 20,
                \ 'type' : 1,
                \ 'offset' : 0
                \ }

    let header = {
                \ 'Host' : 'music.163.com',
                \ 'Referer' : s:url_pre.'search'
                \ }

    let res = webapi#http#post(s:url_pre.'api/search/get', param, header)
    if res.status != '200'
        echom 'http error code:'.res.status
        return []
    endif
    let content = webapi#json#decode(res.content)
    if !has_key(content, 'result') || !has_key(content.result, 'songs')
        return []
    endif
    return map(content.result.songs, 's:extract_entry(v:val)')
endfunction

function! s:extract_entry(dict)
    let album = a:dict.album.name
    let artists = join(map(a:dict.artists, 'v:val.name'), '/')
    return {
                \ 'word' : artists.' -- 【'.album.'】     '.a:dict.name,
                \ 'action__uri' : s:url_pre.'#/song?id='.a:dict.id,
                \ 'kind' : 'media',
                \ 'source' : 'music163'}
endfunction

function! s:refresh(input)
    call unite#print_source_message('Searching ...', 'music163')
    let s:candidates = s:http_get(a:input)
    call unite#clear_message()
endfunction

function! unite#sources#music163#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
