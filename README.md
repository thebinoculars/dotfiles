# Hero's Dotfiles

A comprehensive dotfiles setup for Ubuntu 22.04 with modern CLI tools, Zsh configuration, and development utilities.

## 🚀 Features

- **Zsh + Oh My Zsh** with Powerlevel10k theme
- **100+ CLI tools** including development, productivity, and system utilities
- **Modern alternatives** to classic Unix tools (eza, fd, ripgrep, etc.)
- **Interactive TUI tools** for better terminal experience
- **Flexible installation methods** with automatic dependency resolution

## 📦 Installation

### Quick Install
```bash
bash -c "$(curl https://raw.githubusercontent.com/thebinoculars/dotfiles/master/install.sh)"
```

### Custom Environment Variables
```bash
GIT_USERNAME=your_username GIT_EMAIL=your_email bash -c "$(curl https://raw.githubusercontent.com/thebinoculars/dotfiles/master/install.sh)"
```

## 📋 Package Management

The installer uses a modular `config.ini` system with support for:
- **APT packages** (Ubuntu/Debian)
- **Homebrew** (Linux)
- **Custom installation scripts**
- **GitHub releases** via `eget`
- **Direct commands** for simple installations

### Installation Methods

- `apt` - Install via Ubuntu package manager
- `brew` - Install via Homebrew
- `snap` - Install via Snap packages
- `eget` - Download binaries from GitHub releases
- `script` - Run custom installation scripts from `scripts/` directory
- **Direct commands** - Any other method value is executed as a shell command

### Configuration Options

- `description` - Package description
- `method` - Installation method (required)
- `depends_on` - Comma-separated list of dependencies
- `check` - Custom command to check if package is installed (defaults to `command -v package`)
- `url` - GitHub repository URL (required for `eget` method)
- `variables` - Environment variables for configuration

### Example Configuration

```ini
[example-tool]
description=An example CLI tool
method=brew
depends_on=curl,git
check=command -v example-tool

[custom-install]
description=Tool with custom installation
method=curl -sSL https://example.com/install.sh | bash
depends_on=curl

[github-binary]
description=Binary from GitHub releases
method=eget
url=https://github.com/user/repo
```

## 📁 Structure

```
dotfiles/
├── install.sh           # Main installer script
├── config.ini          # Package definitions and configuration
├── files/              # Configuration files to copy
│   ├── .zshrc
│   ├── .zsh/
│   └── ...
└── scripts/            # Installation scripts for complex packages
    ├── aws.sh
    ├── docker.sh
    └── ...
```

## ⚡ Usage

After installation, you'll have:
- Enhanced Zsh shell with autocompletion and plugins
- Modern CLI tools with better defaults
- Interactive terminal utilities
- Automatic configuration file management

## 🔄 Maintenance

The installer:
- Creates backups of existing files (`*.bak.timestamp`)
- Can be safely re-run to update configurations
- Automatically handles dependencies
- Skips already installed packages

## 🛠️ Customization

To add new packages:
1. Add entry to `config.ini`
2. For complex installations, create script in `scripts/`
3. For simple installations, use direct command in `method`

The system automatically handles dependency resolution and package checking.
