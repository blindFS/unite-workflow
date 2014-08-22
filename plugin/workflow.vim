let g:unite#workflow#show_icon = get(g:, 'unite#workflow#show_icon', 1)
let g:github_user = get(g:, 'github_user', system('git config --get github.user')[:-2])
if strlen(g:github_user) == 0
    let g:github_user = $GITHUB_USER
endif
