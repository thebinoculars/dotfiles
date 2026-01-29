if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
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

# fzf-help configuration
source /usr/share/fzf-help/fzf-help.zsh
zle -N fzf-help-widget
bindkey "^A" fzf-help-widget

# p10k
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# brew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

# Custom dotfiles
