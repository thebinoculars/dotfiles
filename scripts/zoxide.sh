#!/bin/bash
sudo apt install -y zoxide

append_zsh <<'EOF'
# zoxide
eval "$(zoxide init zsh)"
EOF
