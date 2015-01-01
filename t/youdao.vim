source t/pre.vim

describe 'youdao'
  it 'youdao dictionary'
    Unite youdao:vim
    Expect line('$') > 1
    normal q
  end
end
