#!/bin/bash

if command -v z >/dev/null 2>&1; then
  echo "z has already been installed"
  return
fi

curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
sudo mv ~/.local/bin/zoxide /usr/local/bin/
rm -r ~/.local/bin
