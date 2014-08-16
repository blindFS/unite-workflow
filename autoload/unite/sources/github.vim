let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name': 'github',
            \ 'hooks' : {},
            \ 'action_table': {}
            \ }

let s:unite_source.action_table.open = {
            \ 'description' : 'Open Url in a browser',
            \ 'is_quit' : 0
            \ }

function! s:unite_source.action_table.open.func(candidate)
    if has('unix')
        call system('xdg-open https://github.com/'.a:candidate.word.' &')
    elseif has('mac')
        call system('open https://github.com/'.a:candidate.word.' &')
    endif
endfunction

let s:unite_source.action_table.clone = {
            \ 'description' : 'Clone the repo somewhere',
            \ 'is_quit' : 1
            \ }

function! s:unite_source.action_table.clone.func(candidate)
    if !executable('git')
        echoerr 'The executable named git should be in $PATH!'
        return
    endif
    let destdir = unite#util#input('Choose destination directory: ', $PWD, 'file').
                \ '/'.split(a:candidate.word, '/')[1]
    let command = 'git clone https://github.com/'.a:candidate.word.' '.destdir
    call unite#print_source_message('Cloning the repo to '.destdir.'...', s:unite_source.name)
    call system(command)
    execute 'Unite file:'.destdir
endfunction

function! s:unite_source.hooks.on_init(args, context)
    let a:context.source__input =
                \ unite#util#input('Please input search words: ', '')
    call unite#print_source_message('Fetching repos info from the server ...', s:unite_source.name)
    let s:candidates = map(
                \ s:http_get(a:context.source__input, a:context.winheight),
                \ '{"word": v:val,
                \ "kind": "file",
                \ "source": "github"
                \ }')
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__github_user /.*\ze\// contained containedin=ALL
    highlight default link uniteSource__github_user Constant
endfunction

function! s:unite_source.gather_candidates(args, context)
    return s:candidates
endfunction

function! s:http_get(input, number)
    let param = {
                \ "q": a:input,
                \ "per_page": a:number }

    let res = webapi#http#get("https://api.github.com/search/repositories", param)
    let content = webapi#json#decode(res.content)
    return map(content.items, 'v:val.full_name')
endfunction

function! unite#sources#github#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
