let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'gist/search',
            \ 'description' : 'Search for gists.',
            \ 'hooks' : {
            \   'on_syntax' : function('unite#kinds#gist#on_syntax')
            \ },
            \ 'syntax' : 'uniteSource__gist'
            \ }

function! s:unite_source.hooks.on_init(args, context)
    let input = get(a:args, 0, '')
    let input = input != '' ? input :
                \ unite#util#input('Please input search words: ', '')
    call s:refresh(input)
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
    let param = {"q": a:input}
    let res = webapi#http#get('https://gist.github.com/search', param)
    if res.status != '200'
        echom 'http error code:'.res.status
        return []
    endif
    let lines = split(res.content, '\n')
    let gists = filter(lines, 'v:val =~ "css-truncate-target"')
    return map(gists, 's:extract_entry(v:val)')
endfunction

function! s:extract_entry(line)
    let uri = matchstr(a:line, 'a href="/\zs[^>]\+\ze">')
    let id = split(uri, '/')[1]
    let filename = matchstr(a:line, 'class="css-truncate-target">\zs[^<]\+\ze<')
    return {
                \ 'action__id' : id,
                \ 'action__uri' : 'https://gist.github.com/'.uri,
                \ 'fname' : filename,
                \ 'word' : uri.'	'.filename,
                \ 'kind' : 'gist',
                \ 'source' : 'gist/search'}
endfunction

function! s:refresh(input)
    call unite#print_source_message('Fetching gists info from the server ...',
                \ 'gist/search')
    let s:candidates = s:http_get(a:input)
    call unite#clear_message()
endfunction

function! unite#sources#gist_search#define()
    if !exists(':Gist')
        return []
    endif
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
