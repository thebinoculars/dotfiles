#!/bin/bash

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh has already been installed"
  return
fi

echo "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing agnosterzak theme..."
sudo apt update
sudo apt install -y fonts-powerline ttf-ancient-fonts
curl http://raw.github.com/zakaziko99/agnosterzak-ohmyzsh-theme/master/agnosterzak.zsh-theme -Lo "$HOME/.oh-my-zsh/themes/agnosterzak.zsh-theme"

echo "Installing Zsh plugins..."
repos=(
  "https://github.com/zsh-users/zsh-autosuggestions"
  "https://github.com/zsh-users/zsh-history-substring-search"
  "https://github.com/zsh-users/zsh-syntax-highlighting.git"
  "https://github.com/unixorn/git-extra-commands.git"
)

for repo in "${repos[@]}"; do
  git clone "$repo" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$(basename "$repo" .git)"
done

ZSH_WIDGET="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/widget"
if [ ! -d "$ZSH_WIDGET" ]; then
  echo "Creating ZSH_WIDGET directory..."
  mkdir -p "$ZSH_WIDGET"
fi

echo "Installing fzf-help..."
FZF_HELP_DIR="$ZSH_WIDGET/fzf-help"
if [ ! -d "$FZF_HELP_DIR" ]; then
  mkdir -p "$FZF_HELP_DIR"
fi

tmp_dir=$(mktemp -d)
git clone https://github.com/BartSte/fzf-help.git "$tmp_dir"
cp "$tmp_dir/src/"* "$FZF_HELP_DIR"
cp "$tmp_dir/uninstall" "$FZF_HELP_DIR"
rm -rf "$tmp_dir"
