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
  zsh-you-should-use
  zsh-syntax-highlighting
  zsh-history-substring-search
)

zstyle ':omz:update' mode auto

for file in "$HOME"/.zsh/env/*.zsh(N); do
  source "$file"
done

source $ZSH/oh-my-zsh.sh

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

alias -- -="cd -"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

export EDITOR="vim"
export PATH="$HOME/.local/bin:$PATH"

for file in "$HOME"/.zsh/init/*.zsh(N); do
  source "$file"
done

# Machine-specific settings, never touched by the installer. Must stay last.
if [[ -r "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
