source t/pre.vim

describe 'douban movie'
  it 'douban movie'
    Unite douban/movie:gintama
    Expect line('$') > 1
    normal q
  end
end
