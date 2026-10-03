# Hero's Dotfiles

Unattended setup for Ubuntu 24.04 (native or WSL): pick packages from a menu, the installer does the rest and copies the dotfiles into `$HOME`.

## Install

Remote:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/thebinoculars/dotfiles/refs/heads/master/install.sh)"
```

Local, from a clone:
```bash
./install.sh
```

With variables (see [Files and variables](#files-and-variables)):
```bash
GIT_USERNAME="username" GIT_EMAIL="email@example.com" ./install.sh
```

Requires `git`. Safe to re-run: installed packages are skipped.

## Layout

```
config.ini                      One [section] per package
packages/<pkg>/                 Mirrors $HOME: every file is copied to the same path
  install.sh                    Except this one: run by method=script, never copied
  .zsh/env/<pkg>.zsh            Loaded before Oh My Zsh (PATH, fpath)
  .zsh/init/<pkg>.zsh           Loaded after Oh My Zsh (aliases, init)
  .config/<tool>/...            Any other dotfile
packages/common/                Dotfiles that belong to no package (not in config.ini)
install.sh                      Generic installer, knows nothing about specific packages
test.sh                         Runs install.sh in a throwaway Docker container
```

A package folder is optional: a simple package is just a `config.ini` section. Files are copied whether or not the package is installed.

## config.ini

```ini
[mytool]
description=Shown in the menu
method=brew
depends_on=git
check=command -v mytool
setup=export PATH="$HOME/.mytool/bin:$PATH"
required=true
variables=MY_NAME=username,MY_EMAIL=email@example.com
url=https://github.com/owner/repo
```

| Key | Meaning |
|-----|---------|
| `method` | `apt`, `brew`, `eget` (needs `url`), `script` (`packages/<pkg>/install.sh`) or any shell command |
| `depends_on` | Installed first. The first word of `method` is added automatically if it is a package |
| `check` | Succeeds when installed. Default: `dpkg-query` for apt, `command -v <pkg>` otherwise |
| `setup` | Runs in the installer's shell after install or when already installed |
| `required` | Installed before the menu, not shown in it |
| `variables` | `KEY=default` pairs used as `{{KEY}}` in package files |

Install scripts must not prompt, and should use `set -euo pipefail`.

## Zsh snippets

Snippets start with a guard, so they only run when the tool is present:

```zsh
(( $+commands[mytool] )) || return
```

`~/.zsh/env/` and `~/.zsh/init/` are rebuilt on every install. Machine-specific additions go in `~/.zshrc.local`.

## Files and variables

Each file is copied with `{{KEY}}` replaced by the passed value or its default. A changed file is backed up as `<file>.bak.<timestamp>` before being overwritten.

| File | Overwritten when it differs |
|------|-----------------------------|
| Without variables | Always. Change it in the repo, not in `$HOME` |
| With variables | Only when **all** its variables are passed. Otherwise kept, hand edits included |

## Test

Requires Docker, which this repo can install (`docker` package).

Install this working copy:
```bash
./test.sh
```

Install from GitHub master:
```bash
./test.sh remote
```

Open a shell with the repo at `/dotfiles`, then run `/dotfiles/install.sh` by hand:
```bash
./test.sh shell
```

Test another Ubuntu release:
```bash
UBUNTU_VERSION=22.04 ./test.sh
```

The container is deleted on exit. It has no systemd, so services cannot be tested.
