let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'github/issue',
            \ 'description' : 'List github issues of a certain repository.',
            \ 'hooks' : {},
            \ 'action_table': {},
            \ 'syntax' : 'uniteSource__ghissue'
            \ }

function! s:unite_source.hooks.on_init(args, context)
    if exists('s:loaded')
        return
    endif
    let input = get(a:args, 0, '')
    let repo = input != '' ? input :
                \ s:get_current_repo()
    call s:refresh(repo)
    let s:loaded = 1
endfunction

function! s:unite_source.hooks.on_close(args, context)
    call unite#libs#uri#clear_sign()
    if exists('s:loaded')
        unlet s:loaded
    endif
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__ghissue_user /.*\ze\s\+--/
                \ contained containedin=uniteSource__ghissue
    syntax match uniteSource__ghissue_label /【.\{-}】/
                \ contained containedin=uniteSource__ghissue
                \ contained containedin=uniteSource__ghissue
    highlight default link uniteSource__ghissue_user Constant
    highlight default link uniteSource__ghissue_label Todo
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
            let repo = a:context.input
            call s:refresh(repo)
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

function! s:http_get(repo)
    let res = webapi#http#get("https://api.github.com/repos/".a:repo.'/issues')
    let content = webapi#json#decode(res.content)
    if type(content) == 4
        return []
    endif
    return map(content, 's:extract_entry(v:val)')
endfunction

function! s:extract_entry(dict)
    let user = a:dict.user.login
    let title = a:dict.title
    let labels = join(map(a:dict.labels, 'v:val.name'), ', ')
    let labels = labels == '' ? '' : '【'.labels.'】'
    return {
                \ 'id' : a:dict.user.id,
                \ 'icon' : a:dict.user.avatar_url,
                \ 'word' : user.' -- '.title.'  '.labels,
                \ 'action__uri' : a:dict.html_url,
                \ 'action__number' : a:dict.number,
                \ 'kind' : 'issue',
                \ 'source' : 'github/issue'
                \ }

endfunction

function! s:get_current_repo()
    let output = split(system('git remote -v'), '\n')
    let output = filter(output, 'v:val =~ "github"')
    if output == []
        return 'farseer90718/unite-workflow'
    endif
    return matchstr(output[0], 'github.com[/:]\zs.*\ze\.git')
endfunction

function! s:refresh(repo)
    call unite#print_source_message('Getting issues of '.a:repo.' from the server ...',
                \ s:unite_source.name)
    let s:candidates = s:http_get(a:repo)
    call unite#clear_message()
endfunction

function! unite#sources#github_issue#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
