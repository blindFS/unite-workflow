source t/pre.vim

describe 'douban music'
  it 'douban music'
    Unite douban/music:gintama
    Expect line('$') > 1
    normal q
  end
end
