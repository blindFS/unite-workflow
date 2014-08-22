let s:save_cpo = &cpo
set cpo&vim

function! unite#libs#uri#show_icon(download, context, candidates)
    if !executable('wget') || !has('gui_running') ||
                \ !unite#util#has_vimproc() || !g:unite#workflow#show_icon
        return 1
    endif
    let dir = unite#get_data_directory().'/'.split(a:context.source.name, '/')[0].'/'
    if finddir(dir) == ''
        call mkdir(dir, 'p')
    endif
    let bufn = bufnr(a:context.buffer_name)
    if bufn == -1 || len(getbufline(bufn, 1, '$')) < len(a:candidates)
        return 0
    endif
    execute 'sign unplace * buffer=' . bufn

    let finished = 1
    for index in range(len(a:candidates))
        let cand = a:candidates[index]
        let icon = dir. cand.id . '.png'
        let line = a:context.direction =~ '^b' ?
                    \ (len(a:candidates) - index) :
                    \ (index+a:context.start_insert+1)
        if !filereadable(icon) && a:download
            let finished = 0
            call vimproc#popen2('wget ' . cand.icon . ' -O '.icon)
        else
            try
                execute 'sign define workflow_' . cand.id . ' icon='.icon
                execute 'sign place ' . (index+10) . ' line='.line.' name=workflow_'
                            \ . cand.id . ' buffer=' . bufn
            catch
                let finished = 0
            endtry
        endif
    endfor

    if !a:download
        augroup workflow_icon
            autocmd!
        augroup END
    endif
    return finished
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
