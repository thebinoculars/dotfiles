#!/bin/bash

if command -v lazydocker >/dev/null 2>&1; then
  echo "lazydocker has already been installed"
  exit 0
fi

curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
sudo mv ~/.local/bin/lazydocker /usr/local/bin/
rm -r ~/.local/bin
