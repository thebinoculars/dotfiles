#!/bin/bash

BASE_DIR="$HOME/.dot"
ZSHRC_FILE="$HOME/.zshrc"
DOT_FILES_DIR="$BASE_DIR/dot"
SOURCE_FILES_DIR="$BASE_DIR/source"
PACKAGES=(
  'git'
  'vim'
  'zsh'
  'nginx'
  'mysql-server'
  'jq'
)

check_package_installed() {
  PACKAGE_NAME="$1"

  if dpkg -s "$PACKAGE_NAME" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

install_package_if_not_installed() {
  PACKAGE_NAME="$1"

  if check_package_installed "$PACKAGE_NAME"; then
    echo "$PACKAGE_NAME has already installed"
  else
    echo "Install $PACKAGE_NAME..."
    sudo apt update
    sudo apt install -y "$PACKAGE_NAME"
    echo "$PACKAGE_NAME has been successfully installed"
  fi
}

install_oh_my_zsh() {
  echo "Install oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_agnosterzak_theme() {
  echo "Install agnosterzak theme..."
  curl http://raw.github.com/zakaziko99/agnosterzak-ohmyzsh-theme/master/agnosterzak.zsh-theme -Lo "$HOME/.oh-my-zsh/themes/agnosterzak.zsh-theme"
  if [ -f "$ZSHRC_FILE" ]; then
    sed -i 's/ZSH_THEME="[^"]*"/ZSH_THEME="agnosterzak"/' "$ZSHRC_FILE"
  fi
}

for package in ${PACKAGES[*]}; do
  install_package_if_not_installed $package
done

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh has already installed"
else
  install_oh_my_zsh
  install_agnosterzak_theme
fi

if [ -d "$BASE_DIR" ]; then
  echo "$BASE_DIR already exists. Updating from git..."
  git -C "$BASE_DIR" pull origin master
else
  echo "Create $BASE_DIR..."
  git clone https://github.com/antiheroguy/dotfiles.git "$BASE_DIR"
fi

for file in "$DOT_FILES_DIR"/.*; do
  if [ -f "$file" ]; then
    file_name=$(basename "$file")
    target_file="$HOME/$file_name"

    if [ -e "$target_file" ]; then
      echo "Backup $target_file..."
      mv "$target_file" "$target_file.bak"
    fi

    echo "Create symlink from $file to $target_file"
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
