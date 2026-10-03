# Hero's Dotfiles

Unattended setup for Ubuntu 24.04 (native or WSL): pick packages from a menu, the installer does the rest and copies the dotfiles into `$HOME`.

## Install

Remote:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/thebinoculars/dotfiles/refs/heads/master/install.sh)"
```

With variables (see [Files and variables](#files-and-variables)):
```bash
GIT_USERNAME="username" GIT_EMAIL="email@example.com" bash -c "$(curl -fsSL https://raw.githubusercontent.com/thebinoculars/dotfiles/refs/heads/master/install.sh)"
```

Local, from a clone:
```bash
./install.sh
```

Requires `git`. Safe to re-run: installed packages are skipped.

## Layout

```
config.ini                                One [section] per package
home/                                     Mirrors $HOME: every file is copied to the same path
  .zshrc.d/<pkg>.zsh                      Loaded by ~/.zshrc after Oh My Zsh
  .install.d/<pkg>.sh                     Run after the package is installed
install.sh                                Generic installer, knows nothing about specific packages
test.sh                                   Runs install.sh in a throwaway Docker container
```

A package needs no file: a simple package is just a `config.ini` section. Files are copied whether or not the package is installed, so install scripts stay in `~/.install.d/` to be run again by hand.

## config.ini

```ini
[mytool]
description=Shown in the menu
spec=github:owner/mytool
depends_on=git
check=command -v mytool
variables=MY_NAME=username,MY_EMAIL=email@example.com
```

| Key | Meaning |
|-----|---------|
| `method` | `mise` (default), `apt` (system packages, tools without release binaries) or `script` (only its install script) |
| `spec` | What to install, when it is not the section name. mise: a [tool spec](https://mise.jdx.dev) such as `aws-cli`, `node@lts`, `github:owner/repo`, `github:owner/repo[asset_pattern=*linux64*]`. apt: a list of packages, to install add-ons with their tool (`spec=git git-extras`) |
| `depends_on` | Comma-separated packages installed with it: only what it cannot work without (`rga` needs `ripgrep`) |
| `check` | Succeeds when installed, then the package is skipped. Default: `dpkg-query` for apt, `command -v <pkg>` otherwise |
| `variables` | `KEY=default` pairs used as `{{KEY}}` in package files |

A package that is not installed yet is installed by its `method`, then by its install script `.install.d/<pkg>.sh` if there is one: that is where extras of a tool that are not apt packages go (`fzf` installs fzf-help this way). Install scripts must not prompt, and should use `set -euo pipefail`.

The core packages (curl, mise, gum, git, zsh with Oh My Zsh and Powerlevel10k) are listed in `CORE_PACKAGES` in `install.sh`: they are always installed, in that order, before the menu, and are not shown in it.

mise keeps the installed tools in `~/.config/mise/config.toml`: `mise ls` lists them, `mise upgrade` updates them. Tools come from GitHub releases: when installing many, set `GITHUB_TOKEN` (e.g. `GITHUB_TOKEN=$(gh auth token) ./install.sh`) to avoid GitHub's API rate limit.

## Zsh snippets

Snippets start with a guard, so they only run when the tool is present:

```zsh
(( $+commands[mytool] )) || return
```

`~/.zshrc.d/` and `~/.install.d/` are rebuilt on every install. Machine-specific additions go in `~/.zshrc.local`.

## Files and variables

Each file is copied with `{{KEY}}` replaced by the passed value or its default. A changed file is backed up as `<file>.bak.<timestamp>` before being overwritten.

| File | Overwritten when it differs |
|------|-----------------------------|
| Without variables | Always. Change it in the repo, not in `$HOME` |
| With variables | Only when **all** its variables are passed. Otherwise kept, hand edits included |

## Test

Requires Docker, which this repo can install (the `docker` package).

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
