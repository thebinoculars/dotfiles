#!/bin/bash

DIFF_SO_FANCY_VERSION=$(curl -s "https://api.github.com/repos/so-fancy/diff-so-fancy/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
sudo curl -L -o /usr/local/bin/diff-so-fancy "https://github.com/so-fancy/diff-so-fancy/releases/latest/download/diff-so-fancy"
sudo chmod +x /usr/local/bin/diff-so-fancy
