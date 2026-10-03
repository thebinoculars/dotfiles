#!/bin/bash

set -euo pipefail

# NONINTERACTIVE uses `sudo -n`, so make sure sudo credentials are cached
sudo -v
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
