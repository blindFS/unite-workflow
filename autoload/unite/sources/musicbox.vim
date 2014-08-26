let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:url_pre = 'http://music.163.com/'
let s:unite_source = {
            \ 'name' : 'musicbox',
            \ 'description' : '网易音乐盒子搜索',
            \ 'hooks' : {},
            \ 'syntax' : 'uniteSource__musicbox'
            \ }

function! s:unite_source.hooks.on_init(args, context)
    if exists('s:loaded')
        return
    endif
    let input = get(a:args, 0, '')
    let s:input = input != '' ? input :
                \ unite#util#input('Search for songs: ', '')
    call unite#print_source_message('Searching ...', 'musicbox')
    let s:candidates = s:http_get(s:input)
    call unite#clear_message()
    let s:loaded = 1
endfunction

function! s:unite_source.hooks.on_close(args, context)
    if exists('s:loaded')
        unlet s:loaded
    endif
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__musicbox_artists /.*\ze\s\+--/
                \ contained containedin=uniteSource__musicbox
    syntax match uniteSource__musicbox_album /【.\{-}】/
                \ contained containedin=uniteSource__musicbox
                \ contained containedin=uniteSource__musicbox
    highlight default link uniteSource__musicbox_artists Constant
    highlight default link uniteSource__musicbox_album String
endfunction

function! s:unite_source.gather_candidates(args, context)
    if a:context.is_redraw
        if a:context.input != ''
            let s:input = a:context.input
        endif
        call unite#print_source_message('Searching ...', 'musicbox')
        let s:candidates = s:http_get(s:input)
        call unite#clear_message()
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
                \ 'source' : 'musicbox'}
endfunction

function! unite#sources#musicbox#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
