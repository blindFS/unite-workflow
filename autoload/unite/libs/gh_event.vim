let s:save_cpo = &cpo
set cpo&vim

function! unite#libs#gh_event#on_syntax(args, context)
    syntax match uniteSource__github_user /.*\ze\s*---/
                \ contained containedin=uniteSource__github_event
    syntax match uniteSource__github_repo /\s\+[^ ]\{-}\/[^ ]*/
                \ contained containedin=uniteSource__github_event
                \ contains=uniteCandidateInputKeyword
    syntax match uniteSource__github_time /\d\+[mhd] ago/
                \ contained containedin=uniteSource__github_event
    highlight default link uniteSource__github_user Constant
    highlight default link uniteSource__github_repo Keyword
    highlight default link uniteSource__github_time String
endfunction

function! unite#libs#gh_event#get_event(target, source)
    let api_base = 'https://api.github.com/'
    let api_suff = a:source == 'event' ? 'events' : 'received_events'
    if match(a:target, '/') == -1
        let api_addr = api_base.'users/'.a:target.'/'.api_suff
    else
        let api_addr = api_base.'repos/'.a:target.'/'.api_suff
    endif
    let res = webapi#http#get(api_addr)
    let events = webapi#json#decode(res.content)
    return map(events, 's:extract_entry(v:val, a:source)')
endfunction

function! s:extract_entry(dict, source)
    let repo = a:dict.repo.name
    let html_pre = 'https://github.com/'
    let user = a:dict.actor.login
    if a:dict.type == 'PushEvent'
        let words = user.' --- pushed to '.repo
        let url = html_pre.repo.
                    \ '/commit/'.a:dict.payload.commits[0].sha
    elseif a:dict.type == 'PullRequestEvent'
        let words = user.' --- '.a:dict.payload.action.'_PR to '.repo
        let url = html_pre.repo.'/pull/'.a:dict.payload.number
    elseif a:dict.type == 'IssuesEvent'
        let words = user.' --- '.a:dict.payload.action.'_IS to '.repo
        let url = a:dict.payload.issue.html_url
    elseif a:dict.type == 'WatchEvent'
        let words = user.' --- '.a:dict.payload.action.' '.repo
        let url = html_pre.repo
    elseif a:dict.type == 'ForkEvent'
        let words = user.' --- forked '.repo
        let url = html_pre.a:dict.payload.forkee.full_name
    elseif a:dict.type == 'IssueCommentEvent'
        let words = user.' --- commented on '.repo
        let url = a:dict.payload.issue.html_url
    elseif a:dict.type == 'PullRequestReviewCommentEvent'
        let words = user.' --- commented on '.repo
        let url = a:dict.payload.comment.html_url
    elseif a:dict.type == 'CommitCommentEvent'
        let words = user.' --- commented on '.repo
        let url = a:dict.payload.comment.html_url
    elseif a:dict.type == 'CreateEvent'
        let words = user.' --- created '.repo
        let url = html_pre.repo
    elseif a:dict.type == 'DeleteEvent'
        let words = user.' --- deleted a '.
                    \ a:dict.payload.ref_type .
                    \ ' on '.repo
        let url = html_pre.repo
    elseif a:dict.type == 'GollumEvent'
        let words = user.' --- gollum '.repo
        let url = a:dict.payload.pages[0].html_url
    elseif a:dict.type == 'MemberEvent'
        let words = user.' --- '.
                    \ a:dict.payload.action . ' '.
                    \ a:dict.payload.member . ' to '.repo
        let url = html_pre.repo
    elseif a:dict.type == 'PublicEvent'
        let words = user.' --- opened '.repo
        let url = html_pre.repo
    elseif a:dict.type == 'ReleaseEvent'
        let words = user.' --- published '.
                    \ a:dict.payload.release.tag_name
                    \ .' of '.repo
        let url = a:dict.payload.release.html_url
    else
        let words = ''
        let url = html_pre
    endif
    return {
                \ 'id' : a:dict.actor.id,
                \ 'icon' : a:dict.actor.avatar_url,
                \ 'action__uri' : url,
                \ 'action__repo' : repo,
                \ 'word' : words.s:date_diff(a:dict.created_at),
                \ 'kind' : 'uri',
                \ 'source' : 'github/'.a:source
                \ }
endfunction

function! s:date_diff(date)
python << EOF
import vim
import time
from datetime import datetime

date = vim.eval('a:date')
d1 = datetime.strptime(date, '%Y-%m-%dT%H:%M:%SZ')
d2 = datetime.fromtimestamp(time.mktime(time.gmtime()))
if (d2-d1).days > 0:
    diff = str((d2-d1).days) + 'd ago'
elif (d2-d1).seconds/3600 > 0:
    diff = str((d2-d1).seconds/3600) + 'h ago'
else:
    diff = str((d2-d1).seconds/60) + 'm ago'

vim.command('return " '+diff+'"')
EOF
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
