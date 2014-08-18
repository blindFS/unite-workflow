let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name': 'github',
            \ 'hooks' : {},
            \ 'action_table': {},
            \ 'syntax' : 'uniteSource__github'
            \ }

let s:unite_source.action_table.clone = {
            \ 'description' : 'Clone the repo somewhere',
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
    call unite#clear_message()
    execute 'Unite file:'.destdir
endfunction

let s:unite_source.action_table.start = {
            \ 'description' : 'open uri by browser',
            \ 'is_selectable' : 1,
            \ 'is_quit' : 0
            \ }

function! s:unite_source.action_table.start.func(candidates)
    call unite#take_action('start', a:candidates)
endfunction

function! s:unite_source.hooks.on_init(args, context)
    if exists('s:loaded')
        return
    endif
    let a:context.source__input =
                \ unite#util#input('Please input search words: ', '')
    call unite#print_source_message('Fetching repos info from the server ...', s:unite_source.name)
    let s:candidates = map(
                \ s:http_get(a:context.source__input, a:context.winheight),
                \ '{"word" : v:val,
                \ "action__uri" : "https:/github.com/".v:val,
                \ "kind" : "uri",
                \ "source" : "github"
                \ }')
    call unite#clear_message()
    let s:loaded = 1
endfunction

function! s:unite_source.hooks.on_close(args, context)
    unlet s:loaded
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__github_user /.*\ze\//
                \ contained containedin=uniteSource__github__repo
    syntax match uniteSource__github_repo /.*/
                \ contained containedin=uniteSource__github
                \ contains=uniteCandidateInputKeyword,uniteSource__github_user
    highlight default link uniteSource__github_user Constant
    highlight default link uniteSource__github_repo Keyword
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
