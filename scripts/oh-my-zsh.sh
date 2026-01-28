#!/bin/bash

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# plugins
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
  git clone "$repo" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$(basename "$repo" .git)"
done

# fzf-help
tmp_dir=$(mktemp -d)
git clone https://github.com/BartSte/fzf-help.git $tmp_dir
$tmp_dir/install
rm -rf $tmp_dir
