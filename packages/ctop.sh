#!/bin/bash

if command -v ctop >/dev/null 2>&1; then
  echo "ctop has already been installed"
  exit 0
fi

CTOP_VERSION=$(curl -s "https://api.github.com/repos/bcicen/ctop/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -L -o ctop "https://github.com/bcicen/ctop/releases/latest/download/ctop-${CTOP_VERSION}-linux-amd64"
sudo mv ctop /usr/local/bin
sudo chmod +x /usr/local/bin/ctop
