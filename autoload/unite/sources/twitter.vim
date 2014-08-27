let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'twitter',
            \ 'description' : 'twitter timeline.',
            \ 'hooks' : {},
            \ 'action_table': {},
            \ 'syntax' : 'uniteSource__twitter'
            \ }

function! s:unite_source.hooks.on_init(args, context)
    if exists('s:loaded')
        return
    endif
    call s:refresh(a:context.winheight)
    let s:loaded = 1
endfunction

function! s:unite_source.hooks.on_close(args, context)
    call unite#libs#uri#clear_sign()
    if exists('s:loaded')
        unlet s:loaded
    endif
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__twitter_user /.*\ze ::/
                \ contained containedin=uniteSource__twitter
    highlight default link uniteSource__twitter_user Keyword
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
        call s:refresh(a:context.winheight)
    endif
    return s:candidates
endfunction

function! s:unite_source.async_gather_candidates(args, context)
    if unite#libs#uri#show_icon(1, a:context, s:candidates)
        let a:context.is_async = 0
    endif
    return []
endfunction

function! s:http_get(number)
    let ctx = {}
    let configfile = g:unite_data_directory.'/twitter/auth.json'
    if filereadable(configfile)
        let ctx = eval(join(readfile(configfile), ""))
    else
        let ctx.consumer_key = '56CsnzxEQVfnyOZxd2Cl2oPnn'
        let ctx.consumer_secret = '5HwtGeeRNP4mPNwjG4fxVNSIL4tFLJxOjRyjVqG3bjZq4H8qq7'

        let request_token_url = "https://twitter.com/oauth/request_token"
        let auth_url =  "https://twitter.com/oauth/authorize"
        let access_token_url = "https://api.twitter.com/oauth/access_token"

        let ctx = webapi#oauth#request_token(request_token_url, ctx)
        if has("win32") || has("win64")
            exe "!start rundll32 url.dll,FileProtocolHandler ".auth_url."?oauth_token=".ctx.request_token
        elseif executable('xdg-open')
            call system("xdg-open '".auth_url."?oauth_token=".ctx.request_token."'")
        elseif executable('open')
            call system("open '".auth_url."?oauth_token=".ctx.request_token."'")
        endif
        let pin = input("PIN:")
        let ctx = webapi#oauth#access_token(access_token_url, ctx, {"oauth_verifier": pin})
        call writefile([string(ctx)], configfile)
    endif

    let url = "https://api.twitter.com/1.1/statuses/home_timeline.json"
    let ret = webapi#oauth#get(url, ctx, {}, {'count' : a:number})
    let content = webapi#json#decode(ret.content)
    if type(content) != 3
        return []
    endif
    return map(content, 's:extract_entry(v:val)')
endfunction

function! s:extract_entry(dict)
    return {
                \ 'id' : a:dict.user.id,
                \ 'icon' : a:dict.user.profile_image_url,
                \ 'word' : a:dict.user.name.' :: '.a:dict.text,
                \ 'action__uri' : 'https://twitter.com',
                \ 'kind' : 'uri',
                \ 'source' : 'twitter'
                \ }

endfunction

function! s:refresh(limit)
    call unite#print_source_message('Getting tweets ...',
                \ s:unite_source.name)
    let s:candidates = s:http_get(a:limit)
    call unite#clear_message()
endfunction

function! unite#sources#twitter#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
