source t/pre.vim

describe 'youtube'
  it 'youtube search'
    Unite youtube:vim
    Expect line('$') > 1
    normal q
  end
end
