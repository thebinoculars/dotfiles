#!/bin/bash

SD_VERSION=$(curl -s "https://api.github.com/repos/chmln/sd/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -LO https://github.com/chmln/sd/releases/download/v${SD_VERSION}/sd-v${SD_VERSION}-x86_64-unknown-linux-gnu.tar.gz
tar -xzf "sd-v${SD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
sudo mv "sd-v${SD_VERSION}-x86_64-unknown-linux-gnu/sd" /usr/local/bin/
sudo chmod +x /usr/local/bin/sd
rm "sd-v${SD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
rm -rf "sd-v${SD_VERSION}-x86_64-unknown-linux-gnu"
