let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'github/search',
            \ 'description' : 'Search for github repositories.',
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

function! s:unite_source.hooks.on_init(args, context)
    let input = get(a:args, 0, '')
    let input = input != '' ? input :
                \ unite#util#input('Please input search words: ', '')
    call s:refresh(input, a:context.winheight)
endfunction

function! s:unite_source.hooks.on_close(args, context)
    call unite#libs#uri#clear_sign()
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__github_user /.*\ze\//
                \ contained containedin=uniteSource__github_repo
    syntax match uniteSource__github_repo /.*/
                \ contained containedin=uniteSource__github
                \ contains=uniteCandidateInputKeyword,uniteSource__github_user
    highlight default link uniteSource__github_user Constant
    highlight default link uniteSource__github_repo Keyword
endfunction

function! s:unite_source.hooks.on_post_filter(args, context)
    let s:context = a:context
    augroup workflow_icon
        autocmd! TextChanged,TextChangedI <buffer>
                    \ call unite#libs#uri#show_icon(0, s:context, s:context.candidates)
    augroup END
endfunction

function! s:unite_source.gather_candidates(args, context)
    if a:context.is_redraw
        if a:context.input != ''
            let input = a:context.input
            call s:refresh(input, a:context.winheight)
            let a:context.is_async = 1
        endif
    endif
    return s:candidates
endfunction

function! s:unite_source.async_gather_candidates(args, context)
    if unite#libs#uri#show_icon(1, a:context, s:candidates)
        let a:context.is_async = 0
    endif
    return []
endfunction

function! s:http_get(input, number)
    let param = {
                \ "q": a:input,
                \ "per_page": a:number }
    let res = webapi#http#get("https://api.github.com/search/repositories", param)
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
    return {
                \ 'id' : a:dict.owner.id,
                \ 'icon' : a:dict.owner.avatar_url,
                \ 'word' : a:dict.full_name,
                \ 'action__uri' : a:dict.html_url,
                \ 'kind' : 'uri',
                \ 'source' : 'github/search'
                \ }

endfunction

function! s:refresh(input, limit)
    call unite#print_source_message('Fetching repos info from the server ...',
                \ s:unite_source.name)
    let s:candidates = s:http_get(a:input, a:limit)
    call unite#clear_message()
endfunction

function! unite#sources#github_search#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
