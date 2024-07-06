#!/bin/bash

curl -o eget.sh https://zyedidia.github.io/eget.sh
shasum -a 256 eget.sh # verify with hash below
bash eget.sh
sudo mv eget /usr/local/bin/eget
rm eget.sh
