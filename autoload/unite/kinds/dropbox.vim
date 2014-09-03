let s:save_cpo = &cpo
set cpo&vim

function! unite#kinds#dropbox#define()
    return s:kind
endfunction

let s:kind = {
            \ 'name' : 'dropbox',
            \ 'default_action' : 'start',
            \ 'action_table' : {},
            \ 'parents' : ['file']
            \ }

let s:kind.action_table.start = {
            \ 'description' : 'cd or open.',
            \ 'is_quit' : 1
            \ }

function! s:kind.action_table.start.func(candidate)
    if a:candidate.action__mime == 'dir'
        call unite#start([['dropbox', a:candidate.action__path]])
        return
    endif
    if a:candidate.action__mime =~ 'text'
        let path = unite#kinds#dropbox#download(a:candidate.action__path)
        execute 'e '.escape(path, ' \')
    else
        let path = unite#kinds#dropbox#download(a:candidate.action__path)
        let cand = deepcopy(a:candidate)
        let cand.action__uri = path
        call unite#take_parents_action('start', cand, {})
    endif
endfunction

function! unite#kinds#dropbox#download(path)
    let path = expand(unite#util#input('where?  ',
                \ $HOME.'/Dropbox', 'file').
                \ a:path)
    let path_dir = fnamemodify(path, ':p:h')
    if !isdirectory(path_dir)
        call mkdir(path_dir, 'p')
    endif
    if filereadable(path)
        return path
    endif
    let ctx = unite#kinds#dropbox#authorize()
    let url = 'https://api-content.dropbox.com/1/files/auto'.
                \ substitute(a:path, ' ', '%20', 'g')
    call unite#libs#http#oauth_dl(url, ctx, path)
    return path
endfunction

function! unite#kinds#dropbox#authorize()
    let ctx = {}
    let config_dir = unite#get_data_directory().'/dropbox'
    if !isdirectory(config_dir)
        call mkdir(config_dir, 'p')
    endif
    let configfile = config_dir.'/auth.json'

    if filereadable(configfile)
        let ctx = eval(join(readfile(configfile), ""))
    else
        let ctx.consumer_key = '8928ehq03mtarpp'
        let ctx.consumer_secret = '3teavk0kticeauj'

        let request_token_url = 'https://api.dropbox.com/1/oauth/request_token'
        let auth_url =  'https://www.dropbox.com/1/oauth/authorize'
        let access_token_url = 'https://api.dropbox.com/1/oauth/access_token'

        let ctx = webapi#oauth#request_token(request_token_url, ctx)
        let redir_url = auth_url.'?oauth_token='.ctx.request_token
        if has('win32') || has('win64')
            exe '!start rundll32 url.dll,FileProtocolHandler '.redir_url
        elseif executable('xdg-open')
            call system("xdg-open '".redir_url."'")
        elseif executable('open')
            call system("open '".redir_url."'")
        else
            return []
        endif
        call input('press any key to continue')
        let ctx = webapi#oauth#access_token(access_token_url, ctx, {'oauth_verifier': ''})
        call writefile([string(ctx)], configfile)
    endif

    return ctx
endfunction

function! unite#kinds#dropbox#list_path(path)
    let ctx = unite#kinds#dropbox#authorize()
    let url = 'https://api.dropbox.com/1/metadata/auto'.a:path
    let res = webapi#oauth#get(url, ctx, {}, {'list' : 'true'})
    if res.status != '200'
        echom 'http error code:'.res.status
        return []
    endif
    let content = webapi#json#decode(res.content)
    if !has_key(content, 'contents')
        return []
    endif
    return map(content.contents, 'unite#kinds#dropbox#extract_entry(v:val)')
endfunction

function! unite#kinds#dropbox#extract_entry(dict)
    let mime = get(a:dict, 'mime_type', 'dir')
    return {
                \ 'word' : '【'.mime.'】'.
                \   split(a:dict.path, '/')[-1],
                \ 'kind' : 'dropbox',
                \ 'source' : 'dropbox',
                \ 'action__mime' : mime,
                \ 'action__path' : a:dict.path
                \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
