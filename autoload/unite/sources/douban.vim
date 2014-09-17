let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []

function! unite#sources#douban#define()
    let sources = []
    for sou in ['book', 'movie', 'music']
        let source = {
                    \ 'name' : 'douban/'.sou,
                    \ 'description' : 'douban '.sou,
                    \ 'hooks' : {},
                    \ 'syntax' : 'uniteSource__douban'
                    \ }

        function! source.hooks.on_init(args, context)
            let input = get(a:args, 0, '')
            let input = input != '' ? input :
                        \ unite#util#input('Please input search words: ', '')
            let s:kind = split(a:context.source.name, '/')[1]
            call s:refresh(input)
        endfunction

        function! source.hooks.on_close(args, context)
            call unite#libs#uri#clear_sign()
        endfunction

        function! source.hooks.on_syntax(args, context)
            syntax match uniteSource__douban_title /.*\ze --/
                        \ contained containedin=uniteSource__douban
                        \ contains=uniteSource__douban_rank
            syntax match uniteSource__douban_rank /☆ [0-9.]* /
                        \ contained containedin=uniteSource__douban_title
            syntax match uniteSource__douban_people /【.\{-}】/
                        \ contained containedin=uniteSource__douban
                        \ contains=uniteCandidateInputKeyword
            highlight default link uniteSource__douban_title String
            highlight default link uniteSource__douban_people Constant
            highlight default link uniteSource__douban_rank Todo
        endfunction

        function! source.hooks.on_post_filter(args, context)
            let s:context = a:context
            augroup workflow_icon
                autocmd! TextChanged,TextChangedI <buffer>
                            \ call unite#libs#uri#show_icon(0, s:context, s:context.candidates)
            augroup END
        endfunction

        function! source.gather_candidates(args, context)
            if a:context.is_redraw
                if a:context.input != ''
                    let input = a:context.input
                    call s:refresh(input)
                    let a:context.is_async = 1
                endif
            endif
            return s:candidates
        endfunction

        function! source.async_gather_candidates(args, context)
            if unite#libs#uri#show_icon(1, a:context, s:candidates)
                let a:context.is_async = 0
            endif
            return []
        endfunction

        call add(sources, source)
    endfor
    return sources
endfunction

function! s:http_get(input)
    let html_pre = 'https://api.douban.com/v2/'
    if s:kind == 'movie'
        if a:input == ''
            let param = {}
            let url = html_pre.'movie/us_box'
        else
            let param = {
                        \ 'q': a:input,
                        \ }
            let url = html_pre.'movie/search'
        endif
        let key = 'subjects'
    else
        let param = {
                    \ 'q' : a:input
                    \ }
        let url = html_pre.s:kind.'/search'
        let key = s:kind.'s'
    endif

    let res = webapi#http#get(url, param)
    if res.status != '200'
        echom 'http error code:'.res.status
        return []
    endif

    let content = webapi#json#decode(res.content)
    if !has_key(content, key)
        return []
    endif
    return map(content[key], 's:extract_entry(v:val, a:input)')
endfunction

function! s:extract_entry(dict, input)
    let dict = a:input == '' ? a:dict.subject : a:dict
    let icon = s:kind == 'music' ? dict.image : dict.images.small
    let result = {
                \ 'action__id' : dict.id,
                \ 'action__icon' : icon,
                \ 'kind' : 'uri',
                \ 'source' : 'douban/'.s:kind,
                \ 'action__uri' : dict.alt
                \ }
    if s:kind == 'movie'
        let cast = ' ★ '.join(map(dict.casts, 'v:val.name'), ',')
        let dirc = '🎥 '.join(map(dict.directors, 'v:val.name'), ',')
        let middle = dirc.cast
        let tail = dict.year
    elseif s:kind == 'book'
        let middle = join(dict.author, ',')
        let tail = dict.pubdate.' '.dict.publisher
    else
        let middle = join(map(get(dict, 'author', [])[0:2], 'v:val.name'), ',')
        let tail = get(dict.attrs, 'pubdate', ['unknown'])[0]
    endif
    let result.word = '☆ '.substitute(string(dict.rating.average), "'", '', 'g').
                \ ' '.dict.title.' -- 【'.middle.'】-- '.tail
    return result
endfunction

function! s:refresh(input)
    call unite#print_source_message('Fetching '.s:kind.' info from douban ...',
                \ 'douban/'.s:kind)
    let s:candidates = s:http_get(a:input)
    call unite#clear_message()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
