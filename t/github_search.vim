source t/pre.vim

describe 'github test'
  it 'github search'
    Unite github/search:unite.vim
    Expect line('$') > 1
    normal q
  end
end
