#!/bin/bash

OUCH_VERSION=$(curl -s "https://api.github.com/repos/ouch-org/ouch/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
OUCH_FILE_NAME="ouch-x86_64-unknown-linux-gnu"
curl -LO "https://github.com/ouch-org/ouch/releases/download/${OUCH_VERSION}/${OUCH_FILE_NAME}.tar.gz"
tar -xzf "${OUCH_FILE_NAME}.tar.gz"
sudo mv "${OUCH_FILE_NAME}/ouch" /usr/local/bin/
sudo chmod +x /usr/local/bin/ouch
rm "${OUCH_FILE_NAME}.tar.gz"
rm -rf "${OUCH_FILE_NAME}"
