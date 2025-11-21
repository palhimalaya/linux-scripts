#!/bin/bash
# Zsh Installation Script
# Installs Zsh with Oh My Zsh, plugins, and modern configurations

# Source global functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/Global_functions.sh"

# ============================================================================
# CONFIGURATION
# ============================================================================

# Packages to install
ZSH_PACKAGES=(
    "zsh"
    "lsd"
    "mercurial"
    "zplug"
)

# Oh My Zsh plugins to install
OMZ_PLUGINS=(
    "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

# ============================================================================
# SETUP
# ============================================================================

# Create log file
LOG="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S)_zsh.log"
COUNTER=1
while [ -f "$LOG" ]; do
    LOG="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S)_${COUNTER}_zsh.log"
    ((COUNTER++))
done

# Assets directory
ASSETS_DIR="$PARENT_DIR/assets"

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

install_zsh_packages() {
    print_section "Installing Zsh Packages"
    
    for package in "${ZSH_PACKAGES[@]}"; do
        install_package "$package" "$LOG" || echo -e "${WARN} Failed to install $package, continuing..."
    done
}

install_oh_my_zsh() {
    echo -e "${INFO} Installing ${SKY_BLUE}Oh My Zsh${RESET}..."
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo -e "${INFO} Oh My Zsh already installed, skipping..."
        return 0
    fi
    
    sh -c "$(curl -fsSL https://install.ohmyz.sh)" "" --unattended 2>&1 | tee -a "$LOG"
    echo -e "${OK} Oh My Zsh installed successfully"
}

install_omz_plugins() {
    print_section "Installing Oh My Zsh Plugins"
    
    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    
    for plugin_info in "${OMZ_PLUGINS[@]}"; do
        local plugin_name="${plugin_info%%:*}"
        local plugin_url="${plugin_info#*:}"
        local plugin_path="$plugin_dir/$plugin_name"
        
        if [ -d "$plugin_path" ]; then
            echo -e "${INFO} Plugin ${MAGENTA}$plugin_name${RESET} already installed, skipping..."
        else
            echo -e "${INFO} Installing plugin ${MAGENTA}$plugin_name${RESET}..."
            git clone "$plugin_url" "$plugin_path" 2>&1 | tee -a "$LOG"
            echo -e "${OK} Plugin ${MAGENTA}$plugin_name${RESET} installed"
        fi
    done
}

configure_zsh() {
    print_section "Configuring Zsh"
    
    # Backup existing configurations
    backup_file "$HOME/.zshrc"
    backup_file "$HOME/.zprofile"
    
    # Copy custom configurations if available
    if [ -d "$ASSETS_DIR" ]; then
        echo -e "${INFO} Found assets folder, applying custom configurations..."
        
        if [ -f "$ASSETS_DIR/.zshrc" ]; then
            cp "$ASSETS_DIR/.zshrc" "$HOME/" 2>&1 | tee -a "$LOG"
            echo -e "${OK} Applied custom .zshrc"
        fi
        
        if [ -f "$ASSETS_DIR/.zprofile" ]; then
            cp "$ASSETS_DIR/.zprofile" "$HOME/" 2>&1 | tee -a "$LOG"
            echo -e "${OK} Applied custom .zprofile"
        fi
        
        # Copy additional themes
        if [ -d "$HOME/.oh-my-zsh/themes" ] && [ -d "$ASSETS_DIR/add_zsh_theme" ]; then
            cp -r "$ASSETS_DIR/add_zsh_theme/"* "$HOME/.oh-my-zsh/themes/" 2>&1 | tee -a "$LOG"
            echo -e "${OK} Applied additional zsh themes"
        fi
    else
        echo -e "${WARN} No assets folder found, using default Oh My Zsh configuration"
    fi
}

set_default_shell() {
    print_section "Setting Default Shell"
    
    local current_shell=$(basename "$SHELL")
    
    if [ "$current_shell" = "zsh" ]; then
        echo -e "${INFO} Default shell is already ${MAGENTA}zsh${RESET}"
        return 0
    fi
    
    echo -e "${NOTE} Changing default shell to ${MAGENTA}zsh${RESET}..."
    
    # Loop to ensure chsh succeeds
    while ! chsh -s "$(command -v zsh)"; do
        echo -e "${ERROR} Authentication failed. Please enter the correct password."
        sleep 1
    done
    
    echo -e "${OK} Default shell changed to ${MAGENTA}zsh${RESET}"
    echo -e "${NOTE} Please log out and log back in for changes to take effect"
}

install_fastfetch() {
    print_section "Installing Fastfetch"
    
    # Detect architecture
    local arch=$(uname -m)
    local fastfetch_arch="amd64"
    
    case $arch in
        x86_64)
            fastfetch_arch="amd64"
            ;;
        aarch64|arm64)
            fastfetch_arch="aarch64"
            ;;
        *)
            echo -e "${WARN} Unsupported architecture: $arch, defaulting to amd64"
            ;;
    esac
    
    echo -e "${INFO} Installing ${YELLOW}fastfetch${RESET} for $arch..."
    
    case $PKG_MANAGER in
        apt)
            local temp_dir=$(mktemp -d)
            cd "$temp_dir"
            
            local download_url=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
                | grep "browser_download_url.*fastfetch-linux-${fastfetch_arch}.deb" \
                | cut -d '"' -f 4)
            
            if [ -n "$download_url" ]; then
                if download_with_retry "$download_url" "fastfetch.deb"; then
                    sudo dpkg -i fastfetch.deb 2>&1 | tee -a "$LOG"
                    echo -e "${OK} Fastfetch installed successfully"
                else
                    echo -e "${ERROR} Failed to download fastfetch"
                fi
            fi
            
            cd - > /dev/null
            rm -rf "$temp_dir"
            ;;
        pacman)
            install_package "fastfetch" "$LOG" || echo -e "${WARN} Fastfetch not available in repos"
            ;;
        dnf|yum)
            install_package "fastfetch" "$LOG" || echo -e "${WARN} Fastfetch not available in repos"
            ;;
        *)
            echo -e "${WARN} Fastfetch installation not configured for $PKG_MANAGER"
            ;;
    esac
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    print_section "Zsh Installation"
    
    echo -e "${INFO} Package Manager: ${MAGENTA}$PKG_MANAGER${RESET}"
    echo -e "${INFO} Log file: ${CYAN}$LOG${RESET}\n"
    
    # Check if zsh command exists
    if ! command -v zsh >/dev/null 2>&1; then
        # Update package database
        update_package_database "$LOG"
        
        # Install zsh packages
        install_zsh_packages
    else
        echo -e "${INFO} Zsh is already installed"
    fi
    
    # Verify zsh installation
    if ! command -v zsh >/dev/null 2>&1; then
        echo -e "${ERROR} Zsh installation failed. Please check the log file."
        exit 1
    fi
    
    # Install Oh My Zsh
    install_oh_my_zsh
    
    # Install plugins
    install_omz_plugins
    
    # Configure zsh
    configure_zsh
    
    # Set default shell
    set_default_shell
    
    # Install fastfetch
    install_fastfetch
    
    # Summary
    print_section "Installation Complete"
    echo -e "${GREEN}✓ Zsh installation completed successfully!${RESET}"
    echo -e "${INFO} Log file: ${CYAN}$LOG${RESET}"
    echo -e "\n${NOTE} To start using zsh, run: ${CYAN}exec zsh${RESET}"
    echo -e "${NOTE} Or log out and log back in\n"
}

# Run main function
main
