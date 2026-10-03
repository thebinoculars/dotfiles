#!/bin/bash

set -euo pipefail

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
cd "$tmp_dir"
curl -fsSL -O https://install.tunnelmole.com/t357g/install
sudo bash install
