#!/bin/bash

SD_VERSION=$(curl -s "https://api.github.com/repos/chmln/sd/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
SD_FILE_NAME="sd-v${SD_VERSION}-x86_64-unknown-linux-gnu"
curl -LO "https://github.com/chmln/sd/releases/download/v${SD_VERSION}/${SD_FILE_NAME}.tar.gz"
tar -xzf "${SD_FILE_NAME}.tar.gz"
sudo mv "${SD_FILE_NAME}/sd" /usr/local/bin/
sudo chmod +x /usr/local/bin/sd
rm "${SD_FILE_NAME}.tar.gz"
rm -rf "${SD_FILE_NAME}"
