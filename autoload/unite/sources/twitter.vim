let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:dict = expand('<sfile>:p:h').'/../libs/emoji.dict'
let s:unite_source = {
            \ 'name' : 'twitter',
            \ 'description' : 'twitter timeline.',
            \ 'hooks' : {},
            \ 'action_table': {},
            \ 'syntax' : 'uniteSource__twitter'
            \ }

let s:unite_source.action_table.tweet = {
            \ 'description' : 'Create a new tweet.',
            \ 'is_quit' : 0
            \ }

function! s:unite_source.action_table.tweet.func(candidate)
    call s:http_post('new', a:candidate)
endfunction

let s:unite_source.action_table.reply = {
            \ 'description' : 'Reply to a tweet.',
            \ 'is_quit' : 0
            \ }

function! s:unite_source.action_table.reply.func(candidate)
    call s:http_post('reply', a:candidate)
endfunction

let s:unite_source.action_table.retweet = {
            \ 'description' : 'Retweet.',
            \ 'is_quit' : 0
            \ }

function! s:unite_source.action_table.retweet.func(candidate)
    call s:http_post('retweet', a:candidate)
endfunction

let s:unite_source.action_table.favorite = {
            \ 'description' : 'Favorite a tweet.',
            \ 'is_quit' : 0
            \ }

function! s:unite_source.action_table.favorite.func(candidate)
    call s:http_post('favorite', a:candidate)
endfunction

function! s:http_post(action, candidate)
    if !exists('s:ctx')
        return
    endif

    let api_url = 'https://api.twitter.com/1.1/'
    let url = api_url.'statuses/update.json'
    if a:action == 'reply'
        let param = {
                    \ 'status' : unite#util#input('text:', '@'.a:candidate.action__user.' '),
                    \ 'in_reply_to_status_id' : a:candidate.action__id,
                    \ 'trim_user' : 1
                    \ }
    elseif a:action == 'new'
        let param = {
                    \ 'status' : unite#util#input('text:', ''),
                    \ 'trim_user' : 1
                    \ }
    elseif a:action == 'retweet'
        let param = {
                    \ 'trim_user' : 1
                    \ }
        let url = api_url.'statuses/retweet/'.a:candidate.action__id.'.json'
    elseif a:action == 'favorite'
        let param = {
                    \ 'id' : a:candidate.action__id,
                    \ 'include_entities' : 'false'
                    \ }
        let url = api_url.'/favorites/create.json'
    endif

    let ret = webapi#oauth#post(url, s:ctx, {}, param)
    if ret.status == '200'
        redraw
        echo 'Done!. Press <C-L> to refresh.'
    else
        echom 'http error code:'.ret.status
    endif
endfunction

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
    syntax match uniteSource__twitter_user /.*\ze::/
                \ contained containedin=uniteSource__twitter
                \ contains=uniteSource__twitter_status
    syntax match uniteSource__twitter_status /【.\{-}】/
                \ contained containedin=uniteSource__twitter_user
    highlight default link uniteSource__twitter_user Constant
    highlight default link uniteSource__twitter_status Keyword
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
        let s:ctx = eval(join(readfile(configfile), ""))
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
        else
            return []
        endif
        let pin = input("PIN:")
        let s:ctx = webapi#oauth#access_token(access_token_url, ctx, {"oauth_verifier": pin})
        call writefile([string(s:ctx)], configfile)
    endif

    let url = "https://api.twitter.com/1.1/statuses/home_timeline.json"
    let ret = webapi#oauth#get(url, s:ctx, {}, {'count' : a:number})
    let content = webapi#json#decode(
                \ substitute(ret.content,
                \   '\\u\(d\x\{3}\)\\u\(d\x\{3}\)',
                \   '\=s:from_surrogates(submatch(1), submatch(2))',
                \   'g')
                \ )
    if type(content) != 3
        return []
    endif
    return map(content, 's:extract_entry(v:val)')
endfunction

function! s:from_surrogates(high, low)
    let high = str2nr(a:high, 16) - 55296
    let low = str2nr(a:low, 16) - 56320
    let code = printf('&#x%04x;', 65536 + 1024*high + low)
    let lines = readfile(s:dict)
    call filter(lines, 'v:val =~ "'.code.'"')
    return len(lines) > 0 ? lines[0][0:4] : ''
endfunction

function! s:extract_entry(dict)
    let deco = ''
    let deco .= a:dict.favorited? '★' : '☆'
    let deco .= a:dict.favorite_count.','
    let deco .= a:dict.retweeted? '♻ ' : '♲ '
    let deco .= a:dict.retweet_count
    return {
                \ 'id' : a:dict.user.id,
                \ 'icon' : a:dict.user.profile_image_url,
                \ 'word' : '【'.deco.'】'.a:dict.user.name.'::'.a:dict.text,
                \ 'action__uri' : 'https://twitter.com',
                \ 'action__id' : a:dict.id_str,
                \ 'action__user' : a:dict.user.screen_name,
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
