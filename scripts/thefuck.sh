#!/bin/bash

sudo apt install -y thefuck

append_zsh <<'EOF'
# thefuck
eval $(thefuck --alias)
EOF
