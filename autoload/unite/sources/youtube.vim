let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'youtube',
            \ 'description' : 'youtube search.',
            \ 'hooks' : {},
            \ 'syntax' : 'uniteSource__youtube'
            \ }

function! s:unite_source.hooks.on_init(args, context)
    let input = get(a:args, 0, '')
    let input = input != '' ? input :
                \ unite#util#input('Searching keyword: ', '')
    call s:refresh(input)
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__youtube_kind /video\|channel\|playlist/
                \ contained containedin=uniteSource__youtube
    syntax match uniteSource__youtube_channel /【.*】/
                \ contained containedin=uniteSource__youtube
    highlight default link uniteSource__youtube_kind Constant
    highlight default link uniteSource__youtube_channel Keyword
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
                \ 'key' : 'AIzaSyAATDG2sY41TYQyH_tN5S-styaWT9kouDM',
                \ 'part' : 'snippet',
                \ 'maxResults' : 15,
                \ 'q' : a:input
                \ }
    let res = webapi#http#get('https://www.googleapis.com/youtube/v3/search', param)
    if res.status != '200'
        echom 'http error code:'.res.status
        return []
    endif
    let content = webapi#json#decode(res.content)
    if !has_key(content, 'items')
        return []
    endif
    return map(content.items, 's:extract_entry(v:val)')
endfunction

function! s:extract_entry(dict)
    let html_pre = 'https://www.youtube.com/'
    let title = a:dict.snippet.title
    let channel = a:dict.snippet.channelTitle
    let channel = channel == '' ? 'Unknown' : channel
    let kind = split(a:dict.id.kind, '#')[1]

    if kind == 'video'
        let uri = html_pre.'watch?v='.a:dict.id.videoId
    elseif kind == 'channel'
        let uri = html_pre.'channel/'.a:dict.id.channelId
    elseif kind == 'playlist'
        let uri = html_pre.'/playlist?list='.a:dict.id.playlistId
    else
        let uri = html_pre
    endif

    return {
                \ 'word' : kind.' -- 【'.channel.'】 -- '.title,
                \ 'kind' : 'media',
                \ 'action__uri' : uri,
                \ 'source' : 'youtube'}
endfunction

function! s:refresh(input)
    call unite#print_source_message('Searching ...', 'youtube')
    let s:candidates = s:http_get(a:input)
    call unite#clear_message()
endfunction

function! unite#sources#youtube#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
