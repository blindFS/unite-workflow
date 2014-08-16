let s:save_cpo = &cpo
set cpo&vim

if !exists(':Gist')
    echoerr "You need to load mattn's gist-vim first"
    finish
endif

let s:candidates = []
let s:unite_source = {
            \ 'name': 'gist/search',
            \ 'hooks' : {'on_syntax' : function('unite#kinds#gist#on_syntax')},
            \ 'action_table': {},
            \ 'syntax' : 'uniteSource__gist'
            \ }

" function! s:unite_source.hooks.on_syntax(args, context)
"     syntax match uniteSource__gist_user /.*\ze\// contained containedin=uniteSource__gist
"     syntax match uniteSource__gist_fname /[ \t]\+.*$/ contained containedin=uniteSource__gist contains=uniteCandidateInputKeyword
"     highlight default link uniteSource__gist_user Constant
"     highlight default link uniteSource__gist_fname Keyword
" endfunction

function! s:unite_source.hooks.on_init(args, context)
    let a:context.source__input =
                \ unite#util#input('Please input search words: ', '')
    call unite#print_source_message('Fetching gists info from the server ...', 'gist/search')
    let s:candidates = s:http_get(a:context.source__input)
endfunction

function! s:unite_source.gather_candidates(args, context)
    return s:candidates
endfunction

function! s:http_get(input)
    let param = {"q": a:input}

    let res = webapi#http#get("https://gist.github.com/search", param)
    let lines = split(res.content, '\n')
    let gists = filter(lines, 'v:val =~ "css-truncate-target"')
    let entries = map(gists, 's:extract_entry(v:val)')
    return entries
endfunction

function! s:extract_entry(line)
    let uri = matchstr(a:line, 'a href="/\zs[^>]\+\ze">')
    let id = split(uri, '/')[1]
    let filename = matchstr(a:line, 'class="css-truncate-target">\zs[^<]\+\ze<')
    return {
                \ 'id' : id,
                \ 'url' : 'https://gist.github.com/'.uri,
                \ 'fname' : filename,
                \ 'word' : uri.'	'.filename,
                \ 'kind' : 'gist',
                \ 'source' : 'gist/search'}
endfunction

function! unite#sources#gist_search#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
