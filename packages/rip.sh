#!/bin/bash

if command -v rip >/dev/null 2>&1; then
  echo "rip has already been installed"
  return
fi

sudo curl -L -o /usr/local/bin/rip https://github.com/nivekuil/rip/releases/download/0.12.0/rip
sudo chmod +x /usr/local/bin/rip
