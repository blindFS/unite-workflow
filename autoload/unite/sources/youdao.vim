let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []
let s:unite_source = {
            \ 'name' : 'youdao',
            \ 'description' : '有道词典',
            \ 'hooks' : {},
            \ 'syntax' : 'uniteSource__youdao'
            \ }

function! s:unite_source.hooks.on_init(args, context)
    if exists('s:loaded')
        return
    endif
    let input = get(a:args, 0, '')
    let input = input != '' ? input :
                \ unite#util#input('Phrase to translate: ', '')
    call unite#print_source_message('Translating ...', 'youdao')
    let s:candidates = s:http_get(input)
    call unite#clear_message()
    let s:loaded = 1
endfunction

function! s:unite_source.hooks.on_close(args, context)
    if exists('s:loaded')
        unlet s:loaded
    endif
endfunction

function! s:unite_source.hooks.on_syntax(args, context)
    syntax match uniteSource__youdao_kw /Translation:\|Explanation:\|Phonetic:/
                \ contained containedin=uniteSource__youdao
    syntax match uniteSource__youdao_ph /\[.*\]/
                \ contained containedin=uniteSource__youdao
    syntax match uniteSource__youdao_pos /*\s\zs\w\+\./
                \ contained containedin=uniteSource__youdao
    highlight default link uniteSource__youdao_kw Keyword
    highlight default link uniteSource__youdao_ph Todo
    highlight default link uniteSource__youdao_pos Constant
endfunction

function! s:unite_source.gather_candidates(args, context)
    if a:context.is_redraw
        let s:candidates = s:http_get(a:context.input)
    endif
    return s:candidates
endfunction

function! s:http_get(input)
    let param = {
                \ 'q' : a:input,
                \ 'keyfrom' : 'vim-workflow',
                \ 'key' : '1290268654',
                \ 'type' : 'data',
                \ 'doctype' : 'json',
                \ 'version' : '1.1'
                \ }
    let res = webapi#http#get('http://fanyi.youdao.com/openapi.do', param)
    let content = webapi#json#decode(res.content)
    return [s:extract_entry(content)]
endfunction

function! s:extract_entry(dict)
    let basic = get(a:dict, 'basic', {})
    let translation = '    '.get(a:dict, 'translation', [''])[0]
    let phonetic = '    ['.get(basic, 'phonetic', '').']'
    let explanation = join(map(get(basic, 'explains', []), '"    * ".v:val'), "\n")
    return {
                \ 'word' : join(['Translation:', translation, 'Phonetic:', phonetic, 'Explanation:', explanation], "\n"),
                \ 'kind' : 'word',
                \ 'is_multiline' : 1,
                \ 'source' : 'youdao'}
endfunction

function! unite#sources#youdao#define()
    return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
