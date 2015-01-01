source t/pre.vim

describe 'douban book'
  it 'douban book'
    Unite douban/book:gintama
    Expect line('$') > 1
    normal q
  end
end
