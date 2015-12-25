let s:save_cpo = &cpo
set cpo&vim

let s:dict = simplify(expand('<sfile>:p:h').'/../libs/emoji.dict')
let s:source = {
            \ 'name': 'emoji',
            \ 'description' : 'Search for emoji by description.',
            \  "default_action" : "insert",
            \ 'hooks' : {},
            \ 'action_table': {},
            \ 'syntax' : 'uniteSource__emoji'
            \ }

let s:source.action_table.insert = {
            \ 'description' : 'insert emoji',
            \ 'is_quit' : 1
            \ }

function! s:source.action_table.insert.func(candidate)
  let word = matchstr(a:candidate.word, '^.\{-}\ze\s')
  let col = getcurpos()[2]
  let line = getline('.')
  if col < 0 | let col = len(line)| endif
  let pre = matchstr(line, '^.*\%' . col . 'c.')
  let after = line[col :]
  call setline(line('.'), pre . word . after)
endfunction

function! s:source.hooks.on_init(args, context) abort
  let a:context.source__data = readfile(s:dict)
endfunction

function! s:source.hooks.on_close(args, context)
  let a:context.source__data = ''
endfunction

function! s:source.hooks.on_syntax(args, context)
    syntax match uniteSource__emoji_desc /\s\+\zs[A-Z0-9 -]\+/
                \ contained containedin=uniteSource__emoji
                \ contains=uniteCandidateInputKeyword
    highlight default link uniteSource__emoji_desc Normal
endfunction

function! s:source.gather_candidates(args, context)
    return map(
                \ a:context.source__data,
                \ '{"word": v:val,
                \ "kind": "word",
                \ "abbr": v:val,
                \ "source": "emoji",
                \ }')
endfunction

function! unite#sources#emoji#define()
  return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
