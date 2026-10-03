#!/bin/bash

set -euo pipefail

zsh_path=$(command -v zsh)
[ "$(getent passwd "$USER" | cut -d: -f7)" = "$zsh_path" ] || sudo chsh -s "$zsh_path" "$USER"

[ -d "$HOME/.oh-my-zsh" ] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --skip-chsh

custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
repos=(
  "https://github.com/Aloxaf/fzf-tab"
  "https://github.com/MichaelAquilina/zsh-you-should-use"
  "https://github.com/tom-auger/cmdtime"
  "https://github.com/unixorn/git-extra-commands"
  "https://github.com/zpm-zsh/undollar"
  "https://github.com/zsh-users/zsh-autosuggestions"
  "https://github.com/zsh-users/zsh-history-substring-search"
  "https://github.com/zsh-users/zsh-syntax-highlighting"
)
for repo in "${repos[@]}"; do
  dest="$custom_dir/plugins/$(basename "$repo" .git)"
  [ -d "$dest" ] || git clone --depth=1 "$repo" "$dest"
done

[ -d "$custom_dir/themes/powerlevel10k" ] || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$custom_dir/themes/powerlevel10k"
