#!/bin/bash

ZSHRC_FILE="$HOME/.zshrc"
DOTFILES_DIR="$HOME/.dotfiles"
DOT_FILES_DIR="$DOTFILES_DIR/dot"
PACKAGES_DIR="$DOTFILES_DIR/packages"
SOURCE_FILES_DIR="$DOTFILES_DIR/source"
PACKAGES=(
  'git'
  'vim'
  'zsh'
  'nginx'
  'jq'
)

install_packages() {
  for package in "${PACKAGES[@]}"; do
    if dpkg -s "$package" >/dev/null 2>&1; then
      echo "$package has already been installed"
    else
      echo "Installing $package..."
      sudo apt update
      sudo apt install -y "$package"
      echo "$package has been successfully installed"
    fi
  done

  for script in "$PACKAGES_DIR"/*.sh; do
    if [ -f "$script" ]; then
      package_name=$(basename "$script" .sh)
      echo "Running custom installation script for $package_name..."
      source "$script"
    fi
  done
}

setup_dotfiles() {
  if [ -d "$DOTFILES_DIR" ]; then
    echo "$DOTFILES_DIR already exists. Updating from git..."
    git -C "$DOTFILES_DIR" pull origin master
  else
    echo "Creating $DOTFILES_DIR..."
    git clone https://github.com/antiheroguy/dotfiles.git "$DOTFILES_DIR"
  fi

  for file in "$DOT_FILES_DIR"/.*; do
    if [ -f "$file" ]; then
      file_name=$(basename "$file")
      target_file="$HOME/$file_name"

      if [ -e "$target_file" ]; then
        echo "Backing up $target_file..."
        mv "$target_file" "$target_file.bak"
      fi

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

initialize() {
  setup_dotfiles
  install_packages
}

initialize
