#!/bin/bash

sync_music() {
  rclone sync /mnt/c/Users/Hero/Music Open:/ --exclude "desktop.ini" --exclude "/.*/**" --exclude ".*" --local-no-set-modtime
}
