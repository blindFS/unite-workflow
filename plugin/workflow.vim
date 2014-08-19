if !exists('g:github_user')
    let g:github_user = system('git config --get github.user')[:-2]
    if strlen(g:github_user) == 0
        let g:github_user = $GITHUB_USER
    end
endif
