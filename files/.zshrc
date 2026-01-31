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

alias -- -="cd -"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

export EDITOR="vim"
export HISTSIZE=10000

# Custom dotfiles
