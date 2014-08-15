let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name': 'gist',
            \ 'hooks' : {},
            \ 'action_table': {},
            \ 'syntax' : 'uniteSource__gist'
            \ }

let s:unite_source.action_table.open = {
            \ 'description' : 'Open Url in a browser',
            \ 'is_quit' : 0
            \ }

function! s:unite_source.action_table.open.func(candidate)
    if has('unix')
        call system('xdg-open https://gist.github.com/' . split(a:candidate.word, '\t')[0])
    elseif has('mac')
        call system('open https://gist.github.com/' . split(a:candidate.word, '\t')[0])
    endif
endfunction

let s:unite_source.action_table.edit = {
            \ 'description' : 'Edit the gist',
            \ 'is_quit' : 1
            \ }

function! s:unite_source.action_table.edit.func(candidate)
    if !executable('curl')
        echoerr 'curl is needed!'
        return
    endif
    let uri = 'https://gist.githubusercontent.com/'.split(a:candidate.word, '\t')[0].'/raw'
    let fname = g:unite_data_directory.'/gist/'.escape(split(a:candidate.word, '\t')[1], ' \')
    if glob(g:unite_data_directory.'/gist') == ''
        call mkdir(g:unite_data_directory.'/gist')
    endif
    call system('curl '.uri.' -o '.fname)
    execute 'e '.fname
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__gist_user /.*\ze\// contained containedin=uniteSource__gist
    syntax match uniteSource__gist_fname /[ \t]\+.*$/ contained containedin=uniteSource__gist contains=uniteCandidateInputKeyword
    highlight default link uniteSource__gist_user Constant
    highlight default link uniteSource__gist_fname Keyword
endfunction

function! s:unite_source.hooks.on_init(args, context)
    let a:context.source__input =
                \ unite#util#input('Please input search words: ', '')
    call unite#print_source_message('Fetching gists info from the server ...', s:unite_source.name)
    let s:candidates = map(
                \ s:http_get(a:context.source__input),
                \ '{"word": v:val,
                \ "kind": "file",
                \ "source": "gist"
                \ }')
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
    " for e in entries
    "     echom e
    " endfor
endfunction

function! s:extract_entry(line)
    let uri = matchstr(a:line, 'a href="/\zs[^>]\+\ze">')
    let filename = matchstr(a:line, 'class="css-truncate-target">\zs[^<]\+\ze<')
    return uri.'	'.filename
endfunction

function! unite#sources#gist#define()
    return s:unite_source
endfunction
let &cpo = s:save_cpo
unlet s:save_cpo
