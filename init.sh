#!/bin/bash

ZSHRC_FILE="$HOME/.zshrc"
DOTFILES_DIR="$HOME/.dotfiles"
DOT_FILES_DIR="$DOTFILES_DIR/dot"
PACKAGES_DIR="$DOTFILES_DIR/packages"
SOURCE_FILES_DIR="$DOTFILES_DIR/source"
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

  for file in "$DOT_FILES_DIR"/.*; do
    if [ -f "$file" ]; then
      file_name=$(basename "$file")
      target_file="$HOME/$file_name"

      for key in "${!ENV_VARS[@]}"; do
        value="${ENV_VARS[$key]}"
        sed -i "s/{{${key}}}/$value/g" "$file"
      done

      echo "Creating symlink from $file to $target_file"
      ln -sf "$file" "$target_file"
    fi
  done

  for file in "$SOURCE_FILES_DIR"/.*; do
    if [ -f "$file" ]; then
      source_command="source $file"
      if ! grep -qF "$source_command" "$ZSHRC_FILE"; then
        echo "Adding source command to $ZSHRC_FILE..."
        echo "$source_command" >>"$ZSHRC_FILE"
      fi
    fi
  done
}

install_packages() {
  mapfile -t PACKAGES < "$DOTFILES_DIR/packages.txt"
  for package in "${PACKAGES[@]}"; do
    if dpkg -s "$package" >/dev/null 2>&1; then
      echo "$package has already been installed"
      continue
    fi

    echo "Installing $package..."
    sudo apt update
    sudo apt install -y "$package"
  done

  source "oh-my-zsh.sh"

  for script in "$PACKAGES_DIR"/*.sh; do
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
