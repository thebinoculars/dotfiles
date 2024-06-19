export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnosterzak"

zstyle ':omz:update' mode auto
zstyle ':omz:plugins:alias-finder' autoload yes
zstyle ':omz:plugins:alias-finder' longer yes
zstyle ':omz:plugins:alias-finder' exact yes
zstyle ':omz:plugins:alias-finder' cheaper yes

plugins=(alias-finder copyfile dircycle dotenv fzf git safe-paste sudo zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting zsh-navigation-tools)

source $ZSH/oh-my-zsh.sh
