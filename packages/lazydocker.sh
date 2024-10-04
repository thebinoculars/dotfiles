#!/bin/bash

curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
sudo mv $HOME/.local/bin/lazydocker /usr/local/bin/
