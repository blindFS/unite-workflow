let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'toilet',
            \ 'description' : 'Ascii art.',
            \ 'hooks' : {},
            \ }

function! s:unite_source.hooks.on_init(args, context)
    if exists('s:loaded')
        return
    endif
    let input = get(a:args, 0, '')
    let input = input != '' ? input :
                \ unite#util#input('String to convert: ', '')
    call s:get_candidates(input)
    let s:loaded = 1
endfunction

function! s:unite_source.hooks.on_close(args, context)
    if exists('s:loaded')
        unlet s:loaded
    endif
endfunction

function! s:unite_source.gather_candidates(args, context)
    if a:context.is_redraw
        if a:context.input != ''
            let input = a:context.input
            call s:get_candidates(input)
        endif
    endif
    return s:candidates
endfunction

function! s:get_candidates(input)
    let candidates = []
    let g:unite#workflow#figlet_fonts#dir = get(g:, 'unite#workflow#figlet_fonts#dir', '/usr/share/figlet')
    let fonts = split(
                \ unite#util#system(
                \   'find '.g:unite#workflow#figlet_fonts#dir." -name '*.tlf'"),
                \ '\n')
    let fonts = map(fonts, 'split(v:val, "/")[-1]')
    for font in fonts
        call add(candidates, {
                    \ 'word' : unite#util#system(printf(s:command, font, a:input)),
                    \ 'kind' : 'word',
                    \ 'is_multiline' : 1,
                    \ 'source' : 'toilet'
                    \ })
    endfor
    let s:candidates = candidates
endfunction

function! unite#sources#toilet#define()
    if !has('unix') || !executable('find')
        return []
    elseif executable('toilet')
        let s:command = 'toilet -w 999 -f %s %s'
    elseif executable('figlet')
        let s:command = 'figlet -w 999 f %s %s'
    else
        return []
    endif
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
