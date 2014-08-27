let s:save_cpo = &cpo
set cpo&vim

function! unite#kinds#media#define()
    let g:unite#workflow#player = get(g:, 'unite#workflow#player', 'mplayer')
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
        echoerr 'You want to play it directly? You should have you-get installed.'.
        return
    endif
    if !executable(g:unite#workflow#player)
        echoerr 'No '.g:unite#workflow#player.' in $PATH, you may need to change g:unite#workflow#player.'
    endif
    try
        echo 'opening with '.g:unite#workflow#player
        call system('pkill '.g:unite#workflow#player)
        call system('you-get -p '.g:unite#workflow#player.' '.a:candidate.action__uri.' &')
    catch
        echoerr 'Failed to play the selected song.'
    endtry
endfunction

let s:kind.action_table.stop = {
            \ 'description' : 'Stop the player.',
            \ 'is_quit' : 0
            \ }

function! s:kind.action_table.stop.func(candidate)
    call system('pkill '.g:unite#workflow#player)
    call system('pkill you-get')
    echo 'stopped'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
