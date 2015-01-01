source t/pre.vim

describe 'zhihu'
  it 'zhihu daily'
    Unite zhihu
    Expect line('$') > 1
    normal q
  end
end
