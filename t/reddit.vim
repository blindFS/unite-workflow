source t/pre.vim

describe 'reddit'
  it 'subreddit'
    Unite reddit:vim
    Expect line('$') > 1
    normal q
  end
end
