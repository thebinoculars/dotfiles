# Hero's Dotfiles

A comprehensive dotfiles setup for Ubuntu 22.04 with modern CLI tools, Zsh configuration, and development utilities.

## 🚀 Features

- **Zsh + Oh My Zsh** with Powerlevel10k theme
- **150+ CLI tools** including development, productivity, and system utilities
- **Modern alternatives** to classic Unix tools (eza, fd, ripgrep, etc.)
- **Interactive TUI tools** for better terminal experience

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

The installer uses a modular `config.yml` system with support for:
- **APT packages** (Ubuntu/Debian)
- **Homebrew** (Linux)
- **Custom installation scripts**
- **GitHub releases** via `eget`

## 📁 Structure

```
dotfiles/
├── install.sh           # Main installer script
├── config.yml          # Package definitions and configuration
├── files/              # Configuration files to copy
│   ├── .zshrc
│   ├── .gitconfig
│   ├── .zsh/
│   └── .config/
└── scripts/            # Installation scripts for specific tools
```

## ⚡ Usage

After installation, you'll have:
- Enhanced Zsh shell with autocompletion
- Modern CLI tools with better defaults
- Interactive terminal utilities

## 🔄 Maintenance

The installer creates backups of existing files (`*.bak`) and can be safely re-run to update configurations.
