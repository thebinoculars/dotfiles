if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  asdf
  cmdtime
  copybuffer
  copyfile
  copypath
  dircycle
  dotenv
  fzf
  fzf-tab
  git
  git-extra-commands
  git-extras
  safe-paste
  sudo
  undollar
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-syntax-highlighting
  zsh-you-should-use
)

zstyle ':omz:update' mode auto

source $ZSH/oh-my-zsh.sh

# dotfiles
source "$HOME/.zsh/.alias"
source "$HOME/.zsh/.export"
source "$HOME/.zsh/.function"

# fx
source <(fx --comp zsh)

# fzf-help
source /usr/share/fzf-help/fzf-help.zsh
zle -N fzf-help-widget
bindkey "^A" fzf-help-widget

# mpm
eval "$(_MPM_COMPLETE=zsh_source mpm)"

# the fuck
eval $(thefuck --alias)

# zoxide
eval "$(zoxide init zsh)"

# nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# p10k
[[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"

# fastfetch
fastfetch
