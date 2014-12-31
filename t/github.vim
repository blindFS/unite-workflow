!git clone https://github.com/shougo/unite.vim .vim-flavor/deps/shougo_unite.vim

describe 'github test'
  before
    set rtp+=./
    set rtp+=./.vim-flavor/deps/shougo_unite.vim/
    runtime plugin/unite.vim
  end

  it 'github search'
    Unite github/search:unite-workflow
    Expect getline('$') =~ 'farseer'
  end
end
