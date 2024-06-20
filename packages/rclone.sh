#!/bin/bash

if command -v rclone >/dev/null 2>&1; then
  echo "rclone has already been installed"
  return
fi

sudo -v ; curl https://rclone.org/install.sh | sudo bash
