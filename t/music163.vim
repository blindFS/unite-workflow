source t/pre.vim

describe 'music163'
  it 'music163'
    Unite music163:rock
    Expect line('$') > 1
    normal q
  end
end
