let s:save_cpo = &cpo
set cpo&vim

let s:dict = expand('<sfile>:p:h').'/emoji.dict'
let s:unite_source = {
            \ 'name': 'emoji',
            \ 'description' : 'Search for emoji by description.',
            \ 'required_pattern_length': 3,
            \ 'is_volatile': 1,
            \ 'hooks' : {},
            \ 'action_table': {},
            \ 'syntax' : 'uniteSource__emoji'
            \ }

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__emoji_code /&.*;/
                \ contained containedin=uniteSource__emoji
    syntax match uniteSource__emoji_desc /\s\+\zs[A-Z0-9 -]\+/
                \ contained containedin=uniteSource__emoji
                \ contains=uniteCandidateInputKeyword
    highlight default link uniteSource__emoji_code Constant
    highlight default link uniteSource__emoji_desc String
endfunction

function! s:unite_source.gather_candidates(args, context)
    return map(
                \ split(unite#util#system(
                \   printf(s:command, a:context.input)
                \ ), '\n'),
                \ '{"word": v:val,
                \ "kind": "word",
                \ "source": "emoji",
                \ }')
endfunction

function! unite#sources#emoji#define()
    if executable('ag')
        let s:command = 'ag --nocolor -i %s '.s:dict
    elseif executable('ack')
        let s:command = 'ack --nocolor -i %s '.s:dict
    elseif executable('grep')
        let s:command = 'grep -i %s '.s:dict
    else
        return []
    endif
    return s:unite_source
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
