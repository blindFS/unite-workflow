source t/pre.vim

describe 'v2ex'
  it 'v2ex'
    Unite v2ex
    Expect line('$') > 1
    normal q
  end
end
