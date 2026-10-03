#!/bin/bash

set -euo pipefail

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
git clone --depth=1 https://github.com/BartSte/fzf-help.git "$tmp_dir"
"$tmp_dir/install"
