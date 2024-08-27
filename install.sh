#!/bin/bash

set -e

ZSHRC_FILE="$HOME/.zshrc"
DOTFILES_DIR="$HOME/.dotfiles"
declare -A ENV_VARS=(
  ["GIT_USERNAME"]="${GIT_USERNAME:-User}"
  ["GIT_EMAIL"]="${GIT_EMAIL:-email@example.com}"
)

setup_dotfiles() {
  if [ -d "$DOTFILES_DIR" ]; then
    echo "Removing existing $DOTFILES_DIR..."
    rm -rf "$DOTFILES_DIR"
  fi

  echo "Cloning $DOTFILES_DIR..."
  git clone https://github.com/antiheroguy/dotfiles.git "$DOTFILES_DIR"

  find "$DOTFILES_DIR/files" -type f | while read -r file; do
    relative_path="${file#$DOTFILES_DIR/files/}"
    target_file="$HOME/$relative_path"
    target_dir="$(dirname "$target_file")"

    if [ ! -d "$target_dir" ]; then
      echo "Creating directory $target_dir..."
      mkdir -p "$target_dir"
    fi

    for key in "${!ENV_VARS[@]}"; do
      value="${ENV_VARS[$key]}"
      sed -i "s/{{${key}}}/$value/g" "$file"
    done

    echo "Removing existing file $target_file..."
    rm -f "$target_file"

    echo "Copying $file to $target_file..."
    cp "$file" "$target_file"
  done
}

install_packages() {
  if [ -f "$DOTFILES_DIR/packages.txt" ]; then
    echo "Updating package list..."
    sudo apt update
    echo "Installing packages..."
    sudo xargs -a "$DOTFILES_DIR/packages.txt" apt install -y
  fi

  source "$DOTFILES_DIR/oh-my-zsh.sh"

  for script in "$DOTFILES_DIR"/packages/*.sh; do
    package=$(basename "$script" .sh)

    if command -v "$package" >/dev/null 2>&1; then
      echo "$package has already been installed."
      continue
    fi

    echo "Installing $package..."
    source "$script"
  done

  if command -v "eget" >/dev/null 2>&1; then
    echo "Installing packages with eget"
    sudo -E eget -D
  fi
}

initialize() {
  setup_dotfiles
  install_packages
}

initialize
