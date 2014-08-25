## What the hell?

I suppose you know what alfred-workflow is.
This vim plugin is a collection of unite.vim extentions as a alternative to it.

### github events

![ge](./screenshots/github_event.png)

Fetch recent github events of a certain user.

### github feeds

Fetch github timeline of a certain user(defaults to g:github_user).

### github repository searching

Search for github repos by keywords.

### gist user

NOTE:This feature requires [gist-vim](https://github.com/mattn/gist-vim).

![gu](./screenshots/gist_user.png)

List public gists created by a certain user(defaults to g:github_user).
Actions:

* edit, open with `:Gist id`.
* start, open in a browser.

### gist searching

Search for gists.
Similar to gist-user.

### reddit

Fetch hot topics from reddit.
use `g:unite#workflow#reddit#front` to specify user front feed json url.
Should be like this `http://www.reddit.com/.json?feed={hash}&user={username}`.
If not, the fetching scope will be 'all'.
If used with input, the input is taken as subreddit like this:

![re](./screenshots/reddit.png)

### wikipedia

Search for wiki, list matching entries, open selected in a browser.

### apropos

Fast manpage access.

![ap](./screenshots/apropos.png)

### toilet

Note: this feature requires executable 'toilet' or 'figlet'.

Use `g:unite#workflow#figlet_font_dir` to specify where the fonts are stored,
defaults to `/usr/share/figlet`.

![tl](./screenshots/toilet.png)

### emoji

Search for emoji by description.

![em](./screenshots/emoji.png)

### v2ex

Latest topics of http://www.v2ex.com

![v2](./screenshots/v2ex.png)

### youdao

有道词典/翻译

![yd](./screenshots/youdao.png)

### musicbox

网易云音乐搜索

![163](./screenshots/musicbox.png)

## Installation

You need these plugins installed and loaded.

* [unite.vim](https://github.com/shougo/unite.vim)
* [webapi-vim](https://github.com/mattn/webapi-vim)
* [gist-vim](https://github.com/mattn/gist-vim) for gist sources

Then just use your preferred managing tool for this plugin.
If you'd like to load just a part of these features. I suggest that you use neobundle.vim:

``` vim
NeoBundleLazy 'farseer90718/unite-workflow', {
            \ 'unite_sources' : [ your-list ],
            \ 'depends' : [
            \   'mattn/webapi-vim',
            \   'mattn/gist-vim']
            \ }
```

## Customization

* `g:unite#workflow#show_icon` 0 to disable avatar display.
* `g:unite#workflow#reddit#front` as described above.

Example:

``` vim
let g:unite#workflow#reddit#front = 'http://www.reddit.com/.json?feed=foo&user=bar'
call unite#custom#profile(
            \ 'source/github/search, source/github/event, '.
            \ 'source/github/feed, source/gist/search, '.
            \ 'source/gist/user, source/v2ex, '.
            \ 'source/reddit, source/wikipedia',
            \ 'context', {
            \   'keep_focus' : 1,
            \   'no_quit' : 1
            \ })
call unite#custom#profile(
            \ 'source/youdao, source/toilet',
            \ 'context', {
            \   'max_multi_lines' : 20,
            \   'winheight' : 20
            \ })
nnoremap <leader>t  :Unite youdao:<CR>
```

## License

MIT
