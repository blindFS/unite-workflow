source t/pre.vim

describe 'wikipedia'
  it 'wikipedia search'
    Unite youtube:vim
    Expect line('$') > 1
    normal q
  end
end
