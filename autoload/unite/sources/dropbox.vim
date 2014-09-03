let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'dropbox',
            \ 'description' : 'dropbox access.',
            \ 'hooks' : {},
            \ 'action_table': {},
            \ 'syntax' : 'uniteSource__dropbox'
            \ }

function! s:extract_entry(dict)
    return {
                \ 'word' : split(a:dict.path, '/')[-1].
                \   '【'. get(a:dict, 'mime_type', 'dir'). '】',
                \ 'kind' : 'dropbox',
                \ 'source' : 'dropbox'
                \ }
endfunction

function! s:unite_source.hooks.on_init(args, context)
    let path = get(a:args, 0, '')
    call unite#print_source_message('Getting files ...',
                \ s:unite_source.name)
    let s:candidates = unite#kinds#dropbox#list_path(path)
    call unite#clear_message()
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__dropbox_type /【.\{-}】/
                \ contained containedin=uniteSource__dropbox
                \ contains=uniteCandidateInputKeyword
    highlight default link uniteSource__dropbox_type Constant
endfunction

function! s:unite_source.gather_candidates(args, context)
    return s:candidates
endfunction

function! unite#sources#dropbox#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
