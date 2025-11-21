#!/bin/bash
# System Backup Script
# Creates a comprehensive backup of your Pop!_OS configuration

# Source global functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/Global_functions.sh"

# ============================================================================
# CONFIGURATION
# ============================================================================

BACKUP_DIR="$PARENT_DIR/backup-$(date +%Y%m%d-%H%M%S)"
BACKUP_NAME="popos-backup-$(date +%Y%m%d-%H%M%S)"

# ============================================================================
# SETUP
# ============================================================================

LOG="$LOG_DIR/backup-$(date +%Y%m%d-%H%M%S).log"

# ============================================================================
# BACKUP FUNCTIONS
# ============================================================================

create_backup_structure() {
    print_section "Creating Backup Structure"
    
    mkdir -p "$BACKUP_DIR"/{configs,lists,gnome,scripts,fonts,themes}
    echo -e "${OK} Backup directory created: ${CYAN}$BACKUP_DIR${RESET}"
}

backup_package_list() {
    print_section "Backing Up Package Lists"
    
    echo -e "${INFO} Generating installed package list..."
    
    case $PKG_MANAGER in
        apt)
            # Installed packages
            dpkg --get-selections > "$BACKUP_DIR/lists/dpkg-selections.txt"
            apt-mark showmanual > "$BACKUP_DIR/lists/apt-manual.txt"
            
            # Repository list
            cp -r /etc/apt/sources.list* "$BACKUP_DIR/lists/" 2>/dev/null || true
            
            # Flatpak packages
            if command -v flatpak >/dev/null 2>&1; then
                flatpak list --app --columns=application > "$BACKUP_DIR/lists/flatpak-packages.txt"
            fi
            
            # Snap packages
            if command -v snap >/dev/null 2>&1; then
                snap list > "$BACKUP_DIR/lists/snap-packages.txt"
            fi
            ;;
        pacman)
            pacman -Qqe > "$BACKUP_DIR/lists/pacman-explicit.txt"
            pacman -Qqm > "$BACKUP_DIR/lists/pacman-aur.txt"
            ;;
        dnf|yum)
            $PKG_MANAGER list installed > "$BACKUP_DIR/lists/dnf-installed.txt"
            ;;
    esac
    
    echo -e "${OK} Package lists saved"
}

backup_gnome_settings() {
    print_section "Backing Up GNOME Settings"
    
    echo -e "${INFO} Exporting GNOME/Pop Shell settings..."
    
    # GNOME Shell extensions
    if command -v gnome-extensions >/dev/null 2>&1; then
        gnome-extensions list > "$BACKUP_DIR/gnome/extensions-list.txt"
    fi
    
    # Dconf settings (complete GNOME configuration)
    dconf dump / > "$BACKUP_DIR/gnome/dconf-settings.ini"
    
    # Pop Shell specific settings
    dconf dump /org/gnome/shell/extensions/pop-shell/ > "$BACKUP_DIR/gnome/pop-shell-settings.ini" 2>/dev/null || true
    
    # Keybindings
    dconf dump /org/gnome/desktop/wm/keybindings/ > "$BACKUP_DIR/gnome/keybindings.ini"
    dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > "$BACKUP_DIR/gnome/media-keys.ini"
    
    # Desktop appearance
    dconf dump /org/gnome/desktop/interface/ > "$BACKUP_DIR/gnome/interface.ini"
    dconf dump /org/gnome/desktop/background/ > "$BACKUP_DIR/gnome/background.ini"
    
    echo -e "${OK} GNOME settings exported"
}

backup_config_files() {
    print_section "Backing Up Configuration Files"
    
    local configs=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.zshrc"
        "$HOME/.zprofile"
        "$HOME/.gitconfig"
        "$HOME/.vimrc"
        "$HOME/.tmux.conf"
        "$HOME/.config/nvim"
        "$HOME/.config/Code"
        "$HOME/.config/alacritty"
        "$HOME/.config/kitty"
        "$HOME/.config/terminator"
        "$HOME/.config/fish"
        "$HOME/.config/starship.toml"
        "$HOME/.ssh/config"
    )
    
    for config in "${configs[@]}"; do
        if [ -e "$config" ]; then
            local basename=$(basename "$config")
            local dirname=$(dirname "$config")
            
            if [ -d "$config" ]; then
                echo -e "${INFO} Backing up directory: ${CYAN}$basename${RESET}"
                cp -r "$config" "$BACKUP_DIR/configs/" 2>&1 | tee -a "$LOG"
            else
                echo -e "${INFO} Backing up file: ${CYAN}$basename${RESET}"
                cp "$config" "$BACKUP_DIR/configs/" 2>&1 | tee -a "$LOG"
            fi
        fi
    done
    
    echo -e "${OK} Configuration files backed up"
}

backup_fonts() {
    print_section "Backing Up Custom Fonts"
    
    if [ -d "$HOME/.local/share/fonts" ]; then
        echo -e "${INFO} Backing up user fonts..."
        cp -r "$HOME/.local/share/fonts/"* "$BACKUP_DIR/fonts/" 2>&1 | tee -a "$LOG"
        echo -e "${OK} Fonts backed up"
    else
        echo -e "${INFO} No custom fonts found"
    fi
}

backup_themes() {
    print_section "Backing Up Themes and Icons"
    
    # GTK themes
    if [ -d "$HOME/.themes" ]; then
        echo -e "${INFO} Backing up GTK themes..."
        cp -r "$HOME/.themes" "$BACKUP_DIR/themes/gtk-themes" 2>&1 | tee -a "$LOG"
    fi
    
    # Icon themes
    if [ -d "$HOME/.icons" ]; then
        echo -e "${INFO} Backing up icon themes..."
        cp -r "$HOME/.icons" "$BACKUP_DIR/themes/icon-themes" 2>&1 | tee -a "$LOG"
    fi
    
    echo -e "${OK} Themes backed up"
}

backup_scripts() {
    print_section "Backing Up User Scripts"
    
    local script_dirs=(
        "$HOME/.local/bin"
        "$HOME/bin"
        "$HOME/scripts"
    )
    
    for dir in "${script_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            echo -e "${INFO} Backing up: ${CYAN}$basename${RESET}"
            cp -r "$dir" "$BACKUP_DIR/scripts/" 2>&1 | tee -a "$LOG"
        fi
    done
    
    echo -e "${OK} Scripts backed up"
}

create_system_info() {
    print_section "Collecting System Information"
    
    echo -e "${INFO} Gathering system details..."
    
    {
        echo "# System Backup Information"
        echo "# Generated: $(date)"
        echo ""
        echo "## System Details"
        echo "Hostname: $(hostname)"
        echo "OS: $(lsb_release -d | cut -f2)"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo ""
        echo "## User Information"
        echo "Username: $USER"
        echo "Home: $HOME"
        echo "Shell: $SHELL"
        echo ""
        echo "## Package Manager"
        echo "Primary: $PKG_MANAGER"
        echo ""
        echo "## Desktop Environment"
        echo "Session: $XDG_CURRENT_DESKTOP"
        echo "Display Server: $XDG_SESSION_TYPE"
    } > "$BACKUP_DIR/SYSTEM_INFO.txt"
    
    echo -e "${OK} System information saved"
}

create_restore_script() {
    print_section "Creating Restore Script"
    
    cat > "$BACKUP_DIR/restore.sh" << 'RESTORE_SCRIPT'
#!/bin/bash
# Auto-generated Restore Script
# Restores system configuration from backup

set -e

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "  System Configuration Restore"
echo "========================================="
echo ""
echo "This will restore configurations from:"
echo "$BACKUP_DIR"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 1
fi

# Restore GNOME settings
if [ -f "$BACKUP_DIR/gnome/dconf-settings.ini" ]; then
    echo "Restoring GNOME settings..."
    dconf load / < "$BACKUP_DIR/gnome/dconf-settings.ini"
fi

# Restore config files
if [ -d "$BACKUP_DIR/configs" ]; then
    echo "Restoring configuration files..."
    for file in "$BACKUP_DIR/configs/"*; do
        basename=$(basename "$file")
        target="$HOME/$basename"
        
        # Backup existing
        if [ -e "$target" ]; then
            mv "$target" "${target}.backup-$(date +%Y%m%d-%H%M%S)"
        fi
        
        # Copy from backup
        cp -r "$file" "$HOME/"
    done
fi

# Restore fonts
if [ -d "$BACKUP_DIR/fonts" ] && [ "$(ls -A $BACKUP_DIR/fonts)" ]; then
    echo "Restoring fonts..."
    mkdir -p "$HOME/.local/share/fonts"
    cp -r "$BACKUP_DIR/fonts/"* "$HOME/.local/share/fonts/"
    fc-cache -fv
fi

# Restore themes
if [ -d "$BACKUP_DIR/themes/gtk-themes" ]; then
    echo "Restoring GTK themes..."
    mkdir -p "$HOME/.themes"
    cp -r "$BACKUP_DIR/themes/gtk-themes/"* "$HOME/.themes/"
fi

if [ -d "$BACKUP_DIR/themes/icon-themes" ]; then
    echo "Restoring icon themes..."
    mkdir -p "$HOME/.icons"
    cp -r "$BACKUP_DIR/themes/icon-themes/"* "$HOME/.icons/"
fi

# Restore scripts
if [ -d "$BACKUP_DIR/scripts" ]; then
    echo "Restoring user scripts..."
    for dir in "$BACKUP_DIR/scripts/"*; do
        basename=$(basename "$dir")
        target="$HOME/$basename"
        
        if [ -e "$target" ]; then
            mv "$target" "${target}.backup-$(date +%Y%m%d-%H%M%S)"
        fi
        
        cp -r "$dir" "$HOME/"
    done
fi

echo ""
echo "========================================="
echo "✓ Restore completed!"
echo "========================================="
echo ""
echo "Note: You may need to:"
echo "  - Log out and log back in for all changes to take effect"
echo "  - Reinstall packages using the lists in $BACKUP_DIR/lists/"
echo "  - Re-enable GNOME extensions"
echo ""
RESTORE_SCRIPT

    chmod +x "$BACKUP_DIR/restore.sh"
    echo -e "${OK} Restore script created"
}

create_package_restore_script() {
    print_section "Creating Package Restore Script"
    
    cat > "$BACKUP_DIR/restore-packages.sh" << 'PKG_RESTORE'
#!/bin/bash
# Auto-generated Package Restore Script

set -e

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "  Package Restoration"
echo "========================================="
echo ""

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
    PKG_MGR="apt"
elif command -v pacman >/dev/null 2>&1; then
    PKG_MGR="pacman"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
else
    echo "Error: No supported package manager found"
    exit 1
fi

echo "Detected package manager: $PKG_MGR"
echo ""

case $PKG_MGR in
    apt)
        if [ -f "$BACKUP_DIR/lists/apt-manual.txt" ]; then
            echo "Installing packages from apt-manual.txt..."
            sudo apt-get update
            xargs -a "$BACKUP_DIR/lists/apt-manual.txt" sudo apt-get install -y
        fi
        
        # Flatpak
        if [ -f "$BACKUP_DIR/lists/flatpak-packages.txt" ] && command -v flatpak >/dev/null 2>&1; then
            echo "Installing Flatpak packages..."
            while read -r app; do
                flatpak install -y flathub "$app" || true
            done < "$BACKUP_DIR/lists/flatpak-packages.txt"
        fi
        
        # Snap
        if [ -f "$BACKUP_DIR/lists/snap-packages.txt" ] && command -v snap >/dev/null 2>&1; then
            echo "Installing Snap packages..."
            tail -n +2 "$BACKUP_DIR/lists/snap-packages.txt" | awk '{print $1}' | while read -r snap; do
                sudo snap install "$snap" || true
            done
        fi
        ;;
    pacman)
        if [ -f "$BACKUP_DIR/lists/pacman-explicit.txt" ]; then
            echo "Installing packages..."
            sudo pacman -S --needed - < "$BACKUP_DIR/lists/pacman-explicit.txt"
        fi
        ;;
    dnf)
        if [ -f "$BACKUP_DIR/lists/dnf-installed.txt" ]; then
            echo "Installing packages..."
            awk '{print $1}' "$BACKUP_DIR/lists/dnf-installed.txt" | sudo dnf install -y
        fi
        ;;
esac

echo ""
echo "✓ Package restoration completed!"
echo ""
PKG_RESTORE

    chmod +x "$BACKUP_DIR/restore-packages.sh"
    echo -e "${OK} Package restore script created"
}

create_archive() {
    print_section "Creating Backup Archive"
    
    echo -e "${INFO} Compressing backup..."
    
    cd "$PARENT_DIR"
    tar -czf "${BACKUP_NAME}.tar.gz" "$(basename "$BACKUP_DIR")" 2>&1 | tee -a "$LOG"
    
    local archive_size=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
    echo -e "${OK} Archive created: ${CYAN}${BACKUP_NAME}.tar.gz${RESET} (${archive_size})"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    print_section "Pop!_OS System Backup"
    
    echo -e "${INFO} Package Manager: ${MAGENTA}$PKG_MANAGER${RESET}"
    echo -e "${INFO} Backup Directory: ${CYAN}$BACKUP_DIR${RESET}"
    echo -e "${INFO} Log file: ${CYAN}$LOG${RESET}\n"
    
    # Create backup structure
    create_backup_structure
    
    # Collect system information
    create_system_info
    
    # Backup package lists
    backup_package_list
    
    # Backup GNOME settings
    backup_gnome_settings
    
    # Backup configuration files
    backup_config_files
    
    # Backup fonts
    backup_fonts
    
    # Backup themes
    backup_themes
    
    # Backup scripts
    backup_scripts
    
    # Create restore scripts
    create_restore_script
    create_package_restore_script
    
    # Create archive
    create_archive
    
    # Summary
    print_section "Backup Complete"
    echo -e "${GREEN}✓ System backup completed successfully!${RESET}\n"
    echo -e "${INFO} Backup location: ${CYAN}$BACKUP_DIR${RESET}"
    echo -e "${INFO} Archive: ${CYAN}${PARENT_DIR}/${BACKUP_NAME}.tar.gz${RESET}"
    echo -e "${INFO} Log file: ${CYAN}$LOG${RESET}\n"
    
    echo -e "${NOTE} To restore on a new system:"
    echo -e "  1. Extract the archive: ${CYAN}tar -xzf ${BACKUP_NAME}.tar.gz${RESET}"
    echo -e "  2. Run restore script: ${CYAN}./$(basename "$BACKUP_DIR")/restore.sh${RESET}"
    echo -e "  3. Restore packages: ${CYAN}./$(basename "$BACKUP_DIR")/restore-packages.sh${RESET}\n"
}

# Run main function
main
