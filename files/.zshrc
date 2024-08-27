export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnosterzak"

plugins=(
  alias-finder
  colored-man-pages
  copyfile
  dircycle
  dotenv
  fzf
  git
  git-extra-commands
  git-extras
  safe-paste
  sudo
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-syntax-highlighting
)

zstyle ':omz:update' mode auto
zstyle ':omz:plugins:alias-finder' autoload yes
zstyle ':omz:plugins:alias-finder' longer yes
zstyle ':omz:plugins:alias-finder' exact yes
zstyle ':omz:plugins:alias-finder' cheaper yes
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'

source $ZSH/oh-my-zsh.sh

# dotfiles
source "$HOME/.zsh/.alias"
source "$HOME/.zsh/.export"
source "$HOME/.zsh/.function"

# carapace
source <(carapace _carapace)

# fx
source <(fx --comp zsh)

# fzf-help
source /usr/share/fzf-help/fzf-help.zsh
zle -N fzf-help-widget
bindkey "^A" fzf-help-widget

# zoxide
eval "$(zoxide init zsh)"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
