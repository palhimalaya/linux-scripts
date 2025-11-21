# Installation Scripts

A modular collection of installation scripts for setting up development environment components with automatic package manager detection.

## 🚀 Features

- **Auto-detects package manager** - Supports apt, dnf, yum, pacman, zypper, and apk
- **Beautiful progress animations** - Spinner animations during package installation
- **Comprehensive logging** - All operations logged to `Install-Logs/` directory
- **Modular design** - Easy to add new installation scripts
- **Interactive menu** - User-friendly interface for selecting components
- **Automatic backups** - Backs up existing configurations before overwriting

## 📁 Project Structure

```
scripts/
├── install.sh                      # Main orchestrator script
├── install_scripts/
│   ├── Global_functions.sh         # Shared functions and utilities
│   ├── zsh.sh                      # Zsh + Oh My Zsh installation
│   ├── fonts.sh                    # System and Nerd Fonts installation
│   └── backup.sh                   # System configuration backup
├── assets/                         # Optional custom configurations
│   ├── .zshrc                      # Custom zsh configuration
│   ├── .zprofile                   # Custom zsh profile
│   └── add_zsh_theme/              # Additional Oh My Zsh themes
└── Install-Logs/                   # Installation logs (auto-created)
```

## 🎯 Quick Start

### Interactive Mode

Simply run the main installer:

```bash
./install.sh
```

You'll see a menu with options:
1. Install Zsh with Oh My Zsh
2. Install Fonts (System + Nerd Fonts)
3. **Backup System Configuration** ⭐
4. Install All
5. Exit

### Command Line Mode

Install specific components:

```bash
# Install Zsh
./install.sh zsh

# Install Fonts
./install.sh fonts

# Backup your system
./install.sh backup

# Install everything
./install.sh all

# Show help
./install.sh --help
```

### Run Individual Scripts

You can also run scripts directly:

```bash
# Install Zsh
./install_scripts/zsh.sh

# Install Fonts
./install_scripts/fonts.sh

# Backup system
./install_scripts/backup.sh
```

## 📦 What Gets Installed

### Zsh Installation (`zsh.sh`)

**Packages:**
- `zsh` - The Z shell
- `lsd` - Modern ls replacement with icons
- `mercurial` - Version control system
- `zplug` - Zsh plugin manager

**Oh My Zsh Plugins:**
- `zsh-autosuggestions` - Fish-like command suggestions
- `zsh-syntax-highlighting` - Syntax highlighting for commands

**Extras:**
- Sets zsh as default shell
- Installs latest `fastfetch` for system info
- Applies custom configurations from `assets/` if available

### Font Installation (`fonts.sh`)

**System Fonts:**
- `fonts-firacode` - Fira Code with programming ligatures
- `fonts-font-awesome` - Icon font
- `fonts-noto` - Google Noto fonts
- `fonts-noto-cjk` - CJK (Chinese, Japanese, Korean) support
- `fonts-noto-color-emoji` - Color emoji support

**Nerd Fonts:**
- JetBrains Mono Nerd Font
- Fantasque Sans Mono Nerd Font
- Victor Mono Font

All fonts are installed to `~/.local/share/fonts/`

### System Backup (`backup.sh`)

**Creates a comprehensive backup of:**
- **Package lists** - All installed APT/Flatpak/Snap packages
- **GNOME settings** - Complete dconf dump, Pop Shell config, keybindings
- **Configuration files** - Shell configs, git, vim, VS Code, terminal configs
- **Custom fonts** - All fonts from `~/.local/share/fonts/`
- **Themes** - GTK themes and icon themes
- **User scripts** - Scripts from `~/.local/bin/`, `~/bin/`, `~/scripts/`
- **System info** - OS version, kernel, desktop environment

**Generates:**
- Compressed `.tar.gz` archive
- Auto-generated `restore.sh` script
- Auto-generated `restore-packages.sh` script

See [BACKUP_GUIDE.md](BACKUP_GUIDE.md) for detailed usage and restore instructions.

## ⚙️ Configuration

### Custom Zsh Configuration

To use custom zsh configurations, create an `assets` folder:

```bash
mkdir -p assets/add_zsh_theme
```

Add your files:
- `assets/.zshrc` - Your custom zsh configuration
- `assets/.zprofile` - Your custom zsh profile
- `assets/add_zsh_theme/` - Additional Oh My Zsh themes

The scripts will automatically detect and use these files.

### Adding New Installation Scripts

1. Create a new script in `install_scripts/`:

```bash
#!/bin/bash
# Source global functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/Global_functions.sh"

# Your installation logic here
main() {
    print_section "My Component Installation"
    install_package "my-package" "$LOG"
}

main
```

2. Add it to `install.sh` menu (optional)

3. Make it executable:

```bash
chmod +x install_scripts/my-script.sh
```

## 🛠️ Global Functions Reference

The `Global_functions.sh` provides utilities for all scripts:

### Package Management
- `install_package <package> [log_file]` - Install with progress animation
- `reinstall_package <package> [log_file]` - Reinstall package
- `uninstall_package <package> [log_file]` - Remove package
- `is_package_installed <package>` - Check if installed
- `update_package_database [log_file]` - Update package lists

### Utilities
- `print_section <title>` - Print formatted section header
- `download_with_retry <url> <output> [attempts]` - Download with retry logic
- `backup_file <file>` - Create timestamped backup
- `show_progress <pid> <name>` - Show spinner animation

### Variables
- `$PKG_MANAGER` - Detected package manager (apt, dnf, yum, pacman, zypper, apk)
- `$LOG_DIR` - Log directory path
- `$SCRIPT_DIR` - Current script directory
- `$PARENT_DIR` - Parent directory
- Color variables: `$OK`, `$ERROR`, `$NOTE`, `$INFO`, `$WARN`, `$GREEN`, `$RED`, etc.

## 📝 Logs

All installation logs are saved to `Install-Logs/` with timestamps:

```
Install-Logs/
├── install-20251121-045326_zsh.log
└── install-20251121-050123_fonts.log
```

Check logs for detailed installation output and troubleshooting.

## 🔧 Troubleshooting

### Permission Denied
Make scripts executable:
```bash
chmod +x install.sh install_scripts/*.sh
```

### Package Not Found
Some packages may not be available in all repositories. Check the log file for details. The script will continue with a warning.

### Oh My Zsh Insecure Directories Warning
If you see warnings about insecure completion directories:
```bash
sudo chown root:root /path/to/insecure/file
sudo chmod g-w,o-w /path/to/insecure/file
```

### Zsh Not Default After Installation
Log out and log back in, or run:
```bash
exec zsh
```

## 📋 Requirements

- Linux system with supported package manager
- `curl` and `git` installed
- Internet connection
- sudo privileges

## 🎨 Customization

### Change Spinner Animation
Edit `Global_functions.sh` and modify the `spin_chars` array in `show_progress()`:

```bash
local spin_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
```

### Add More Packages
Edit the package arrays in individual scripts:

```bash
# In zsh.sh
ZSH_PACKAGES=(
    "zsh"
    "lsd"
    "your-package-here"
)
```

## 🤝 Contributing

Feel free to add more installation scripts following the existing pattern:

1. Source `Global_functions.sh`
2. Use provided utility functions
3. Create proper log files
4. Add progress animations
5. Handle errors gracefully

## 📄 License

Free to use and modify as needed.

## 🙏 Acknowledgments

Built with modularity and ease of use in mind. Designed to be easily extensible for future installation needs.
