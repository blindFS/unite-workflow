let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:direct = {
            \ 'name' : 'dropbox/files',
            \ 'description' : 'dropbox access.',
            \ 'hooks' : {
            \   'on_syntax' : function('unite#sources#dropbox#syntax')
            \ },
            \ 'gather_candidates' : function('unite#sources#dropbox#gc'),
            \ 'syntax' : 'uniteSource__dropbox'
            \ }

let s:search = deepcopy(s:direct)
let s:search.name = 'dropbox/search'
let s:search.description = 'dropbox search.'

function! s:search.hooks.on_init(args, context)
    let keywords = get(a:args, 0, '')
    call unite#print_source_message('Searching for files ...',
                \ s:search.name)
    if keywords == ''
        let keywords = unite#util#input('Search keywords:', '')
        let s:candidates = unite#kinds#dropbox#search(keywords)
    endif
    call unite#clear_message()
endfunction

function! s:direct.hooks.on_init(args, context)
    let path = get(a:args, 0, '')
    call unite#print_source_message('Getting files ...',
                \ s:direct.name)
    let s:candidates = unite#kinds#dropbox#list_path(path)
    call unite#clear_message()
endfunction

function! unite#sources#dropbox#syntax(args, context)
    syntax match uniteSource__dropbox_type /【.\{-}】/
                \ contained containedin=uniteSource__dropbox
                \ contains=uniteCandidateInputKeyword
    highlight default link uniteSource__dropbox_type Constant
endfunction

function! unite#sources#dropbox#gc(args, context)
    return s:candidates
endfunction

function! unite#sources#dropbox#define()
    return [s:direct, s:search]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
