let s:save_cpo = &cpo
set cpo&vim

function! unite#kinds#media#define()
    return s:kind
endfunction

let s:kind = {
            \ 'name' : 'media',
            \ 'default_action' : 'start',
            \ 'action_table' : {},
            \ 'parents' : ['uri']
            \ }

let s:kind.action_table.open = {
            \ 'description' : 'Open with you-get',
            \ 'is_quit' : 0
            \ }

function! s:kind.action_table.open.func(candidate)
    if !executable('you-get')
        echom '想要播放？ 需要 you-get, 你懂的。'.
        return
    endif
    let g:unite#workflow#player = get(g:, 'unite#workflow#player', 'mplayer')
    if !executable(g:unite#workflow#player)
        echom '默认使用 mplayer，如需替换，请修改变量: g:unite#workflow#player'
    endif
    try
        echo 'opening with '.g:unite#workflow#player
        call system('pkill '.g:unite#workflow#player)
        call system('you-get -p '.g:unite#workflow#player.' '.a:candidate.action__uri.' &')
    catch
        echoerr 'Failed to play the selected song.'
    endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
