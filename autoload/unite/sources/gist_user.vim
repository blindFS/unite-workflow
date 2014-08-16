let s:save_cpo = &cpo
set cpo&vim

if !exists(':Gist')
    echoerr "You need to load mattn's gist-vim first"
    finish
endif

let s:candidates = []
let s:unite_source = {
            \ 'name': 'gist/user',
            \ 'hooks' : {'on_syntax' : function('unite#kinds#gist#on_syntax')},
            \ 'action_table': {},
            \ 'syntax' : 'uniteSource__gist'
            \ }


if !exists('g:github_user')
    let g:github_user = system('git config --get github.user')[:-2]
    if strlen(g:github_user) == 0
        let g:github_user = $GITHUB_USER
    end
endif

function! s:unite_source.gather_candidates(args, context)
    return s:candidates
endfunction

function! s:unite_source.hooks.on_init(args, context)
    let s:username = get(a:args, 0, g:github_user)
    call unite#print_source_message('Fetching gists of user '.
                \ s:username.' ...', 'gist/user')
    let gists = gist#list(s:username)
    let s:candidates = map(gists, 's:extract_entry(v:val)')
endfunction

function! s:extract_entry(dict)
    let fname = keys(a:dict.files)[0]
    let id = a:dict.id
    return {
                \ 'id' : id,
                \ 'url' : a:dict.html_url,
                \ 'word' : s:username.'/'.id.'	'.fname,
                \ 'kind' : 'gist',
                \ 'source' : 'gist/user'
                \ }
endfunction

function! unite#sources#gist_user#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
