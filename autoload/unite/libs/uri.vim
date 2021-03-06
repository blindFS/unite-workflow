let s:save_cpo = &cpo
set cpo&vim

let s:signs = {}
let s:procs = {}
function! unite#libs#uri#show_icon(download, context, candidates)
    if !executable('wget') || !has('gui_running') ||
                \ !unite#util#has_vimproc() || !g:unite#workflow#show_icon
        return 1
    endif
    let dir = unite#get_data_directory().'/'.split(a:context.source.name, '/')[0].'/'
    if finddir(dir) == ''
        call mkdir(dir, 'p')
    endif
    let bufn = bufnr('[unite] - '.a:context.buffer_name)
    if bufwinnr(a:context.buffer_name) == -1
        return 0
    endif
    execute 'sign unplace * buffer=' . bufn

    let finished = 1
    let prompt = getline(1) =~ '^[\t ]*'.a:context.prompt
    for index in range(len(a:candidates))
        let cand = a:candidates[index]
        let icon = dir. cand.action__id . '.png'
        let line = a:context.direction =~ '^b' ?
                    \ (len(a:candidates) - index) :
                    \ (index+prompt+1)
        if !filereadable(icon) && a:download
            let finished = 0
            let proc = vimproc#popen2('wget ' . cand.action__icon . ' -O '.icon)
            let s:procs[proc.pid] = proc
        else
            if a:download
                let s:signs[cand.action__id] = 1
            endif
            try
                execute 'sign define workflow_' . cand.action__id . ' icon='.icon
                execute 'sign place ' . (index+10) . ' line='.line.' name=workflow_'
                            \ . cand.action__id . ' buffer=' . bufn
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
    if finished
        call unite#libs#uri#wait4children()
    endif
    return finished
endfunction

function! unite#libs#uri#clear_sign()
    execute 'sign unplace * buffer=' . bufnr('%')
    for id in keys(s:signs)
        try
            execute 'sign undefine workflow_'.id
        catch
        endtry
    endfor
endfunction

function! unite#libs#uri#wait4children()
    for pid in keys(s:procs)
        call s:procs[pid].waitpid()
    endfor
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
