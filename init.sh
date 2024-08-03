#!/bin/bash

set -e

ZSHRC_FILE="$HOME/.zshrc"
DOTFILES_DIR="$HOME/.dotfiles"
declare -A ENV_VARS=(
  ["GIT_USERNAME"]="${GIT_USERNAME:-Hero}"
  ["GIT_EMAIL"]="${GIT_EMAIL:-vndhero@gmail.com}"
)

setup_dotfiles() {
  if [ -d "$DOTFILES_DIR" ]; then
    rm -rf "$DOTFILES_DIR"
  fi

  echo "Cloning $DOTFILES_DIR..."
  git clone https://github.com/antiheroguy/dotfiles.git "$DOTFILES_DIR"

  find "$DOTFILES_DIR/files" -type f | while read -r file; do
    relative_path="${file#$DOTFILES_DIR/files/}"
    target_file="$HOME/$relative_path"
    target_dir="$(dirname "$target_file")"

    if [ ! -d "$target_dir" ]; then
      echo "Creating directory $target_dir"
      mkdir -p "$target_dir"
    fi

    if [ -f "$target_file" ] || [ -L "$target_file" ]; then
      echo "Removing existing file or symlink $target_file"
      rm -f "$target_file"
    fi

    echo "Copying $file to $target_file"
    cp "$file" "$target_file"
  done

  for file in "$DOTFILES_DIR/sources/.*"; do
    if [ -f "$file" ]; then
      source_command="source $file"
      if ! grep -qF "$source_command" "$ZSHRC_FILE"; then
        echo "Adding $source_command to $ZSHRC_FILE..."
        echo "$source_command" >> "$ZSHRC_FILE"
      fi
    fi
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
      echo "$package has already been installed"
      continue
    fi

    echo "Installing $package..."
    source "$script"
  done

  if command -v "eget" >/dev/null 2>&1; then
    EGET_CONFIG="$HOME/.eget.toml" sudo -E eget -D
  fi
}

initialize() {
  setup_dotfiles
  install_packages
}

initialize
