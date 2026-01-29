#!/bin/bash

brew install fx

append_zsh <<'EOF'
# fx
source <(fx --comp zsh)
EOF
