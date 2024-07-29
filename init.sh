#!/bin/bash

set +e

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

  for file in "$DOTFILES_DIR"/files/.*; do
    if [ -f "$file" ]; then
      file_name=$(basename "$file")
      target_file="$HOME/$file_name"

      for key in "${!ENV_VARS[@]}"; do
        value="${ENV_VARS[$key]}"
        sed -i "s/{{${key}}}/$value/g" "$file"
      done

      if [ -f "$target_file" ]; then
        echo "Removing existing file $target_file"
        rm -f "$target_file"
      fi

      echo "Copying $file to $target_file"
      cp "$file" "$target_file"
    fi
  done

  for file in "$DOTFILES_DIR"/source/.*; do
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
  mapfile -t PACKAGES <"$DOTFILES_DIR/packages.txt"
  sudo apt update
  for package in "${PACKAGES[@]}"; do
    if dpkg -s "$package" >/dev/null 2>&1; then
      echo "$package has already been installed"
      continue
    fi

    echo "Installing $package..."
    sudo apt install -y "$package"
  done

  source "oh-my-zsh.sh"

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

set -e
