#!/bin/bash
# Font Installation Script
# Installs essential fonts and Nerd Fonts for terminal and development

# Source global functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/Global_functions.sh"

# ============================================================================
# CONFIGURATION
# ============================================================================

# System fonts to install
FONTS=(
    "fonts-firacode"
    "fonts-font-awesome"
    "fonts-noto"
    "fonts-noto-cjk"
    "fonts-noto-color-emoji"
)

# Nerd Fonts to install
NERD_FONTS=(
    "JetBrainsMono"
    "FantasqueSansMono"
    "VictorMono"
)

# ============================================================================
# SETUP
# ============================================================================

# Create log file
LOG="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S)_fonts.log"
COUNTER=1
while [ -f "$LOG" ]; do
    LOG="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S)_${COUNTER}_fonts.log"
    ((COUNTER++))
done

# Font directory
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

install_system_fonts() {
    print_section "Installing System Fonts"
    
    for font in "${FONTS[@]}"; do
        install_package "$font" "$LOG"
    done
}

install_jetbrains_mono() {
    local font_name="JetBrainsMono"
    local install_dir="$FONT_DIR/JetBrainsMonoNerd"
    
    echo -e "${INFO} Installing ${YELLOW}$font_name Nerd Font${RESET}..."
    
    # Remove existing installation
    if [ -d "$install_dir" ]; then
        rm -rf "$install_dir" 2>&1 | tee -a "$LOG"
    fi
    mkdir -p "$install_dir"
    
    # Download and extract
    local temp_file="/tmp/JetBrainsMono.tar.xz"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    
    if download_with_retry "$download_url" "$temp_file"; then
        tar -xJf "$temp_file" -C "$install_dir" 2>&1 | tee -a "$LOG"
        rm -f "$temp_file"
        echo -e "${OK} ${YELLOW}$font_name${RESET} installed successfully"
    else
        echo -e "${ERROR} Failed to install $font_name" | tee -a "$LOG"
        return 1
    fi
}

install_fantasque_sans() {
    local font_name="FantasqueSansMono"
    local install_dir="$FONT_DIR/FantasqueSansMonoNerd"
    
    echo -e "${INFO} Installing ${YELLOW}$font_name Nerd Font${RESET}..."
    
    # Remove existing installation
    if [ -d "$install_dir" ]; then
        rm -rf "$install_dir"
    fi
    mkdir -p "$install_dir"
    
    # Download and extract
    local temp_file="/tmp/FantasqueSansMono.zip"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FantasqueSansMono.zip"
    
    if download_with_retry "$download_url" "$temp_file"; then
        unzip -o -q "$temp_file" -d "$install_dir" 2>&1 | tee -a "$LOG"
        rm -f "$temp_file"
        echo -e "${OK} ${YELLOW}$font_name${RESET} installed successfully"
    else
        echo -e "${ERROR} Failed to install $font_name" | tee -a "$LOG"
        return 1
    fi
}

install_victor_mono() {
    local font_name="VictorMono"
    local install_dir="$FONT_DIR/VictorMono"
    
    echo -e "${INFO} Installing ${YELLOW}$font_name Font${RESET}..."
    
    # Remove existing installation
    if [ -d "$install_dir" ]; then
        rm -rf "$install_dir"
    fi
    mkdir -p "$install_dir"
    
    # Download and extract
    local temp_file="/tmp/VictorMonoAll.zip"
    local download_url="https://rubjo.github.io/victor-mono/VictorMonoAll.zip"
    
    if download_with_retry "$download_url" "$temp_file"; then
        unzip -o -q "$temp_file" -d "$install_dir" 2>&1 | tee -a "$LOG"
        rm -f "$temp_file"
        echo -e "${OK} ${YELLOW}$font_name${RESET} installed successfully"
    else
        echo -e "${ERROR} Failed to install $font_name" | tee -a "$LOG"
        return 1
    fi
}

install_nerd_fonts() {
    print_section "Installing Nerd Fonts"
    
    install_jetbrains_mono
    install_fantasque_sans
    install_victor_mono
}

update_font_cache() {
    echo -e "\n${INFO} Updating font cache..."
    fc-cache -fv 2>&1 | tee -a "$LOG"
    echo -e "${OK} Font cache updated"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    print_section "Font Installation"
    
    echo -e "${INFO} Package Manager: ${MAGENTA}$PKG_MANAGER${RESET}"
    echo -e "${INFO} Log file: ${CYAN}$LOG${RESET}\n"
    
    # Update package database
    update_package_database "$LOG"
    
    # Install system fonts
    install_system_fonts
    
    # Install Nerd Fonts
    install_nerd_fonts
    
    # Update font cache
    update_font_cache
    
    # Summary
    print_section "Installation Complete"
    echo -e "${GREEN}✓ All fonts installed successfully!${RESET}"
    echo -e "${INFO} Log file: ${CYAN}$LOG${RESET}\n"
}

# Run main function
main
