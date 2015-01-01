source t/pre.vim

describe 'turing'
  it 'turing robot'
    Unite turing:新闻
    Expect line('$') > 1
    normal q
  end
end
