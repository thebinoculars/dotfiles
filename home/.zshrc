if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

# Before the plugins: some need tools installed by mise
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

plugins=(
  cmdtime
  copybuffer
  copyfile
  copypath
  dircycle
  dotenv
  ${commands[fzf]:+fzf}
  ${commands[fzf]:+fzf-tab}
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

source $ZSH/oh-my-zsh.sh

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

alias -- -="cd -"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

export EDITOR="nano"
export PATH="$HOME/.local/bin:$PATH"

for file in "$HOME"/.zshrc.d/*.zsh(N); do
  source "$file"
done

# Machine-specific settings, never touched by the installer. Must stay last.
if [[ -r "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
