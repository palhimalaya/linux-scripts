#!/bin/bash
# Applications Installation Script
# Install popular applications organized by category
# Author: palhimalaya

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/Global_functions.sh"

LOG_FILE="$LOG_DIR/applications-$(date +%Y%m%d-%H%M%S).log"

# ============================================================================
# BANNER
# ============================================================================

show_applications_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              Applications Installation                     ║"
    echo "║                      by palhimalaya                        ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}\n"
}

# ============================================================================
# BROWSER INSTALLATIONS
# ============================================================================

install_google_chrome() {
    print_section "Installing Google Chrome"
    
    if command -v google-chrome &> /dev/null; then
        echo -e "${INFO} Google Chrome is already installed"
        google-chrome --version
        return 0
    fi
    
    echo -e "${INFO} Downloading Google Chrome..."
    local temp_deb="/tmp/google-chrome-stable_current_amd64.deb"
    
    if download_with_retry "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" "$temp_deb"; then
        echo -e "${INFO} Installing Google Chrome..."
        sudo dpkg -i "$temp_deb" >> "$LOG_FILE" 2>&1 || sudo apt-get install -f -y >> "$LOG_FILE" 2>&1
        rm -f "$temp_deb"
        echo -e "${OK} Google Chrome installed successfully"
        google-chrome --version
    else
        echo -e "${ERROR} Failed to download Google Chrome"
        return 1
    fi
}

install_firefox() {
    print_section "Installing Firefox"
    
    if command -v firefox &> /dev/null; then
        echo -e "${INFO} Firefox is already installed"
        firefox --version
        return 0
    fi
    
    install_package "firefox" "$LOG_FILE"
    echo -e "${OK} Firefox installed successfully"
    firefox --version
}

install_brave() {
    print_section "Installing Brave Browser"
    
    if command -v brave-browser &> /dev/null; then
        echo -e "${INFO} Brave is already installed"
        brave-browser --version
        return 0
    fi
    
    echo -e "${INFO} Adding Brave repository..."
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg >> "$LOG_FILE" 2>&1
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list >> "$LOG_FILE" 2>&1
    
    update_package_database "$LOG_FILE"
    install_package "brave-browser" "$LOG_FILE"
    
    echo -e "${OK} Brave installed successfully"
    brave-browser --version
}

install_edge() {
    print_section "Installing Microsoft Edge"
    
    if command -v microsoft-edge &> /dev/null; then
        echo -e "${INFO} Microsoft Edge is already installed"
        microsoft-edge --version
        return 0
    fi
    
    echo -e "${INFO} Adding Microsoft Edge repository..."
    sudo curl -fsSLo /usr/share/keyrings/microsoft-edge.gpg https://packages.microsoft.com/keys/microsoft.asc >> "$LOG_FILE" 2>&1
    echo "deb [signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list >> "$LOG_FILE" 2>&1
    
    update_package_database "$LOG_FILE"
    install_package "microsoft-edge-stable" "$LOG_FILE"
    
    echo -e "${OK} Microsoft Edge installed successfully"
    microsoft-edge --version
}

install_all_browsers() {
    print_section "Installing All Browsers"
    
    local failed=0
    install_google_chrome || ((failed++))
    install_firefox || ((failed++))
    install_brave || ((failed++))
    install_edge || ((failed++))
    
    echo -e "\n${CYAN}════════════════════════════════════════${RESET}"
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ All browsers installed successfully!${RESET}"
    else
        echo -e "${YELLOW}${BOLD}⚠ $failed browser(s) failed to install${RESET}"
    fi
    echo -e "${CYAN}════════════════════════════════════════${RESET}\n"
}

# ============================================================================
# COMMUNICATION TOOLS
# ============================================================================

install_slack() {
    print_section "Installing Slack"
    
    if command -v slack &> /dev/null || flatpak list | grep -q "com.slack.Slack"; then
        echo -e "${INFO} Slack is already installed"
        return 0
    fi
    
    # Try native package first
    case $PKG_MANAGER in
        apt)
            # Check if slack is available in repos
            if apt-cache search slack-desktop | grep -q "^slack-desktop"; then
                echo -e "${INFO} Installing Slack from native repository..."
                install_package "slack-desktop" "$LOG_FILE"
                echo -e "${OK} Slack installed successfully"
                return 0
            fi
            ;;
        dnf|yum)
            # Fedora/RHEL - check if available
            if dnf list slack 2>/dev/null | grep -q slack; then
                install_package "slack" "$LOG_FILE"
                echo -e "${OK} Slack installed successfully"
                return 0
            fi
            ;;
        pacman)
            # Arch - check AUR or repos
            if pacman -Ss slack | grep -q "^extra/slack"; then
                install_package "slack-desktop" "$LOG_FILE"
                echo -e "${OK} Slack installed successfully"
                return 0
            fi
            ;;
    esac
    
    # Fall back to Flatpak
    echo -e "${WARN} Slack not available in native repositories"
    echo -e "${NOTE} Installing via Flatpak (sandboxed application)"
    
    if ! command -v flatpak &> /dev/null; then
        echo -e "${INFO} Installing Flatpak..."
        install_package "flatpak" "$LOG_FILE"
        echo -e "${INFO} Adding Flathub repository..."
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >> "$LOG_FILE" 2>&1
    fi
    
    echo -e "${INFO} Installing Slack via Flatpak..."
    flatpak install -y flathub com.slack.Slack
    echo -e "${OK} Slack installed successfully (via Flatpak)"
    echo -e "${NOTE} Launch with: ${CYAN}flatpak run com.slack.Slack${RESET}"
}

install_discord() {
    print_section "Installing Discord"
    
    if command -v discord &> /dev/null; then
        echo -e "${INFO} Discord is already installed"
        return 0
    fi
    
    echo -e "${INFO} Downloading Discord..."
    local temp_deb="/tmp/discord.deb"
    
    if download_with_retry "https://discord.com/api/download?platform=linux&format=deb" "$temp_deb"; then
        echo -e "${INFO} Installing Discord..."
        sudo dpkg -i "$temp_deb" >> "$LOG_FILE" 2>&1 || sudo apt-get install -f -y >> "$LOG_FILE" 2>&1
        rm -f "$temp_deb"
        echo -e "${OK} Discord installed successfully"
    else
        echo -e "${ERROR} Failed to download Discord"
        return 1
    fi
}

install_telegram() {
    print_section "Installing Telegram"
    
    if command -v telegram-desktop &> /dev/null || flatpak list | grep -q "org.telegram.desktop"; then
        echo -e "${INFO} Telegram is already installed"
        return 0
    fi
    
    # Try native package first
    case $PKG_MANAGER in
        apt)
            # Ubuntu/Debian - check if available in repos
            if apt-cache search telegram-desktop | grep -q "^telegram-desktop"; then
                echo -e "${INFO} Installing Telegram from native repository..."
                install_package "telegram-desktop" "$LOG_FILE"
                echo -e "${OK} Telegram installed successfully"
                return 0
            fi
            ;;
        dnf|yum)
            # Fedora/RHEL
            if dnf list telegram-desktop 2>/dev/null | grep -q telegram-desktop; then
                install_package "telegram-desktop" "$LOG_FILE"
                echo -e "${OK} Telegram installed successfully"
                return 0
            fi
            ;;
        pacman)
            # Arch
            if pacman -Ss telegram-desktop | grep -q "telegram-desktop"; then
                install_package "telegram-desktop" "$LOG_FILE"
                echo -e "${OK} Telegram installed successfully"
                return 0
            fi
            ;;
    esac
    
    # Fall back to Flatpak
    echo -e "${WARN} Telegram not available in native repositories"
    echo -e "${NOTE} Installing via Flatpak (sandboxed application)"
    
    if ! command -v flatpak &> /dev/null; then
        echo -e "${INFO} Installing Flatpak..."
        install_package "flatpak" "$LOG_FILE"
        echo -e "${INFO} Adding Flathub repository..."
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >> "$LOG_FILE" 2>&1
    fi
    
    echo -e "${INFO} Installing Telegram via Flatpak..."
    flatpak install -y flathub org.telegram.desktop
    echo -e "${OK} Telegram installed successfully (via Flatpak)"
    echo -e "${NOTE} Launch with: ${CYAN}flatpak run org.telegram.desktop${RESET}"
}

install_zoom() {
    print_section "Installing Zoom"
    
    if command -v zoom &> /dev/null; then
        echo -e "${INFO} Zoom is already installed"
        return 0
    fi
    
    echo -e "${INFO} Downloading Zoom..."
    local temp_deb="/tmp/zoom_amd64.deb"
    
    if download_with_retry "https://zoom.us/client/latest/zoom_amd64.deb" "$temp_deb"; then
        echo -e "${INFO} Installing Zoom..."
        sudo dpkg -i "$temp_deb" >> "$LOG_FILE" 2>&1 || sudo apt-get install -f -y >> "$LOG_FILE" 2>&1
        rm -f "$temp_deb"
        echo -e "${OK} Zoom installed successfully"
    else
        echo -e "${ERROR} Failed to download Zoom"
        return 1
    fi
}

install_all_communication() {
    print_section "Installing All Communication Tools"
    
    local failed=0
    install_slack || ((failed++))
    install_discord || ((failed++))
    install_telegram || ((failed++))
    install_zoom || ((failed++))
    
    echo -e "\n${CYAN}════════════════════════════════════════${RESET}"
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ All communication tools installed successfully!${RESET}"
    else
        echo -e "${YELLOW}${BOLD}⚠ $failed tool(s) failed to install${RESET}"
    fi
    echo -e "${CYAN}════════════════════════════════════════${RESET}\n"
}

# ============================================================================
# DEVELOPER TOOLS (IDEs/Editors)
# ============================================================================

install_vscode() {
    print_section "Installing Visual Studio Code"
    
    if command -v code &> /dev/null; then
        echo -e "${INFO} VSCode is already installed"
        code --version
        return 0
    fi
    
    echo -e "${INFO} Adding VSCode repository..."
    sudo curl -fsSLo /usr/share/keyrings/packages.microsoft.gpg https://packages.microsoft.com/keys/microsoft.asc >> "$LOG_FILE" 2>&1
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >> "$LOG_FILE" 2>&1
    
    update_package_database "$LOG_FILE"
    install_package "code" "$LOG_FILE"
    
    echo -e "${OK} VSCode installed successfully"
    code --version
}

install_cursor() {
    print_section "Installing Cursor"
    
    if [ -f "$HOME/.local/bin/cursor" ]; then
        echo -e "${INFO} Cursor is already installed"
        return 0
    fi
    
    echo -e "${INFO} Downloading Cursor AppImage..."
    local cursor_dir="$HOME/.local/share/cursor"
    local cursor_bin="$HOME/.local/bin/cursor"
    
    mkdir -p "$cursor_dir"
    mkdir -p "$HOME/.local/bin"
    
    if download_with_retry "https://downloader.cursor.sh/linux/appImage/x64" "$cursor_dir/cursor.AppImage"; then
        chmod +x "$cursor_dir/cursor.AppImage"
        
        # Create launcher script
        cat > "$cursor_bin" << 'EOF'
#!/bin/bash
exec "$HOME/.local/share/cursor/cursor.AppImage" "$@"
EOF
        chmod +x "$cursor_bin"
        
        echo -e "${OK} Cursor installed successfully"
        echo -e "${NOTE} Launch with: ${CYAN}cursor${RESET}"
    else
        echo -e "${ERROR} Failed to download Cursor"
        return 1
    fi
}

install_antigravity() {
    print_section "Installing Antigravity"
    
    if command -v antigravity &> /dev/null; then
        echo -e "${INFO} Antigravity is already installed"
        antigravity --version
        return 0
    fi
    
    echo -e "${INFO} Installing Antigravity..."
    install_package "antigravity" "$LOG_FILE"
    
    echo -e "${OK} Antigravity installed successfully"
    antigravity --version
}

install_all_developer_tools() {
    print_section "Installing All Developer Tools"
    
    local failed=0
    install_vscode || ((failed++))
    install_cursor || ((failed++))
    install_antigravity || ((failed++))
    
    echo -e "\n${CYAN}════════════════════════════════════════${RESET}"
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ All developer tools installed successfully!${RESET}"
    else
        echo -e "${YELLOW}${BOLD}⚠ $failed tool(s) failed to install${RESET}"
    fi
    echo -e "${CYAN}════════════════════════════════════════${RESET}\n"
}

# ============================================================================
# MEDIA APPLICATIONS
# ============================================================================

install_spotify() {
    print_section "Installing Spotify"
    
    if command -v spotify &> /dev/null || flatpak list | grep -q "com.spotify.Client"; then
        echo -e "${INFO} Spotify is already installed"
        return 0
    fi
    
    # Try native package first
    case $PKG_MANAGER in
        apt)
            # Check if spotify-client is available
            if apt-cache search spotify-client | grep -q "^spotify-client"; then
                echo -e "${INFO} Installing Spotify from native repository..."
                install_package "spotify-client" "$LOG_FILE"
                echo -e "${OK} Spotify installed successfully"
                return 0
            fi
            ;;
        dnf|yum)
            # Fedora/RHEL - usually needs third-party repo
            if dnf list spotify-client 2>/dev/null | grep -q spotify; then
                install_package "spotify-client" "$LOG_FILE"
                echo -e "${OK} Spotify installed successfully"
                return 0
            fi
            ;;
        pacman)
            # Arch - check AUR
            if pacman -Ss spotify | grep -q "spotify"; then
                install_package "spotify" "$LOG_FILE"
                echo -e "${OK} Spotify installed successfully"
                return 0
            fi
            ;;
    esac
    
    # Fall back to Flatpak
    echo -e "${WARN} Spotify not available in native repositories"
    echo -e "${NOTE} Installing via Flatpak (sandboxed application)"
    
    if ! command -v flatpak &> /dev/null; then
        echo -e "${INFO} Installing Flatpak..."
        install_package "flatpak" "$LOG_FILE"
        echo -e "${INFO} Adding Flathub repository..."
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >> "$LOG_FILE" 2>&1
    fi
    
    echo -e "${INFO} Installing Spotify via Flatpak..."
    flatpak install -y flathub com.spotify.Client
    echo -e "${OK} Spotify installed successfully (via Flatpak)"
    echo -e "${NOTE} Launch with: ${CYAN}flatpak run com.spotify.Client${RESET}"
}

install_vlc() {
    print_section "Installing VLC Media Player"
    
    if command -v vlc &> /dev/null; then
        echo -e "${INFO} VLC is already installed"
        vlc --version | head -1
        return 0
    fi
    
    install_package "vlc" "$LOG_FILE"
    echo -e "${OK} VLC installed successfully"
    vlc --version | head -1
}

install_obs() {
    print_section "Installing OBS Studio"
    
    if command -v obs &> /dev/null; then
        echo -e "${INFO} OBS Studio is already installed"
        obs --version
        return 0
    fi
    
    echo -e "${INFO} Adding OBS Studio PPA..."
    sudo add-apt-repository -y ppa:obsproject/obs-studio >> "$LOG_FILE" 2>&1
    
    update_package_database "$LOG_FILE"
    install_package "obs-studio" "$LOG_FILE"
    
    echo -e "${OK} OBS Studio installed successfully"
    obs --version
}

install_pipewire_rnnoise() {
    print_section "Enabling PipeWire RNNoise (Noise Suppression)"
    
    # Check if already configured
    if [ -f "$HOME/.config/pipewire/pipewire.conf.d/99-input-denoising.conf" ]; then
        echo -e "${INFO} PipeWire RNNoise is already configured"
        return 0
    fi
    
    # Install required packages
    echo -e "${INFO} Installing required packages..."
    install_package "pipewire" "$LOG_FILE"
    install_package "libpipewire-0.3-modules" "$LOG_FILE"
    
    # Check if RNNoise LADSPA plugin exists
    local rnnoise_path="/usr/lib/x86_64-linux-gnu/ladspa/librnnoise_ladspa.so"
    
    if [ ! -f "$rnnoise_path" ]; then
        echo -e "${INFO} RNNoise LADSPA plugin not found, downloading..."
        
        # Install unzip if needed
        if ! command -v unzip &> /dev/null; then
            echo -e "${INFO} Installing unzip..."
            install_package "unzip" "$LOG_FILE"
        fi
        
        # Create directory
        echo -e "${INFO} Creating LADSPA plugin directory..."
        if ! sudo mkdir -p /usr/lib/x86_64-linux-gnu/ladspa; then
            echo -e "${ERROR} Failed to create plugin directory"
            return 1
        fi
        
        # Download to user's home directory (no permission issues)
        local temp_file="$HOME/.cache/rnnoise.zip"
        mkdir -p "$HOME/.cache"
        
        # Download pre-built RNNoise LADSPA plugin (it's a ZIP file, not tar.gz)
        echo -e "${INFO} Downloading RNNoise plugin from GitHub..."
        if ! curl -L "https://github.com/werman/noise-suppression-for-voice/releases/download/v1.10/linux-rnnoise.zip" -o "$temp_file" 2>&1 | tee -a "$LOG_FILE"; then
            echo -e "${ERROR} Failed to download RNNoise plugin"
            echo -e "${NOTE} Check your internet connection or see log: $LOG_FILE"
            rm -f "$temp_file"
            return 1
        fi
        
        # Verify download
        if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
            echo -e "${ERROR} Downloaded file is missing or empty"
            rm -f "$temp_file"
            return 1
        fi
        
        # Extract plugin
        echo -e "${INFO} Extracting plugin..."
        if ! sudo unzip -o "$temp_file" -d /usr/lib/x86_64-linux-gnu/ladspa/ 2>&1 | tee -a "$LOG_FILE"; then
            echo -e "${ERROR} Failed to extract RNNoise plugin"
            rm -f "$temp_file"
            return 1
        fi
        
        rm -f "$temp_file"
        
        # The plugin extracts to a subdirectory, create symlink to expected location
        local extracted_path="/usr/lib/x86_64-linux-gnu/ladspa/linux-rnnoise/ladspa/librnnoise_ladspa.so"
        
        if [ -f "$extracted_path" ]; then
            echo -e "${INFO} Creating symlink to plugin..."
            sudo ln -sf "$extracted_path" "$rnnoise_path"
            echo -e "${OK} RNNoise LADSPA plugin installed successfully"
        elif [ -f "$rnnoise_path" ]; then
            echo -e "${OK} RNNoise LADSPA plugin installed successfully"
        else
            echo -e "${ERROR} Plugin file not found after extraction"
            echo -e "${NOTE} Expected at: $rnnoise_path"
            echo -e "${NOTE} Or at: $extracted_path"
            return 1
        fi
    else
        echo -e "${INFO} RNNoise LADSPA plugin already installed"
    fi
    
    # Create PipeWire config directory
    mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
    
    # Create noise suppression configuration
    echo -e "${INFO} Configuring noise suppression..."
    cat > "$HOME/.config/pipewire/pipewire.conf.d/99-input-denoising.conf" << 'EOF'
context.modules = [
    {   name = libpipewire-module-filter-chain
        args = {
            node.description = "Noise Canceling Source"
            media.name       = "Noise Canceling Source"
            filter.graph = {
                nodes = [
                    {
                        type   = ladspa
                        name   = rnnoise
                        plugin = /usr/lib/x86_64-linux-gnu/ladspa/librnnoise_ladspa.so
                        label  = noise_suppressor_stereo
                        control = {
                            "VAD Threshold (%)" = 50.0
                        }
                    }
                ]
            }
            capture.props = {
                node.name      = "capture.rnnoise_source"
                node.passive   = true
                audio.rate     = 48000
            }
            playback.props = {
                node.name      = "rnnoise_source"
                media.class    = Audio/Source
                audio.rate     = 48000
            }
        }
    }
]
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${OK} PipeWire RNNoise configured successfully"
    else
        echo -e "${ERROR} Failed to create configuration file"
        return 1
    fi
    
    echo -e "\n${CYAN}════════════════════════════════════════${RESET}"
    echo -e "${NOTE} ${YELLOW}Restart required${RESET} - Run: ${CYAN}systemctl --user restart pipewire${RESET}"
    echo -e "${NOTE} After restart, select ${BOLD}'Noise Canceling Source'${RESET} as your microphone"
    echo -e "${CYAN}════════════════════════════════════════${RESET}\n"
    
    # Offer to restart PipeWire now
    read -p "$(echo -e ${CYAN}Restart PipeWire now? [y/N]:${RESET} )" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${INFO} Restarting PipeWire..."
        if systemctl --user restart pipewire pipewire-pulse 2>&1 | tee -a "$LOG_FILE"; then
            echo -e "${OK} PipeWire restarted successfully"
            echo -e "${NOTE} Open ${BOLD}Settings → Sound${RESET} and select ${BOLD}'Noise Canceling Source'${RESET} as input"
        else
            echo -e "${ERROR} Failed to restart PipeWire"
            echo -e "${NOTE} Try manually: ${CYAN}systemctl --user restart pipewire${RESET}"
            return 1
        fi
    fi
}


install_noisetorch() {
    print_section "Installing NoiseTorch (Noise Suppression)"
    
    if command -v noisetorch &> /dev/null || [ -f "$HOME/.local/bin/noisetorch" ]; then
        echo -e "${INFO} NoiseTorch is already installed"
        return 0
    fi
    
    echo -e "${INFO} Downloading NoiseTorch..."
    local noisetorch_dir="$HOME/.local/share/noisetorch"
    local noisetorch_bin="$HOME/.local/bin/noisetorch"
    
    mkdir -p "$noisetorch_dir"
    mkdir -p "$HOME/.local/bin"
    
    # Get latest release URL
    local download_url="https://github.com/noisetorch/NoiseTorch/releases/download/v0.12.2/NoiseTorch_x64_v0.12.2.tgz"
    
    echo -e "${INFO} Downloading and extracting NoiseTorch..."
    if curl -L "$download_url" -o "/tmp/noisetorch.tgz" >> "$LOG_FILE" 2>&1; then
        tar -xzf "/tmp/noisetorch.tgz" -C "$noisetorch_dir" >> "$LOG_FILE" 2>&1
        chmod +x "$noisetorch_dir/"*.x64
        
        # Create symlink
        ln -sf "$noisetorch_dir/"*.x64 "$noisetorch_bin"
        
        rm -f "/tmp/noisetorch.tgz"
        
        echo -e "${OK} NoiseTorch installed successfully"
        echo -e "${NOTE} Launch with: ${CYAN}noisetorch${RESET}"
        echo -e "${NOTE} Or search for 'NoiseTorch' in applications"
    else
        echo -e "${ERROR} Failed to download NoiseTorch"
        return 1
    fi
}

install_easyeffects() {
    print_section "Installing EasyEffects (Audio Effects Suite)"
    
    if command -v easyeffects &> /dev/null || flatpak list | grep -q "com.github.wwmm.easyeffects"; then
        echo -e "${INFO} EasyEffects is already installed"
        return 0
    fi
    
    # Try native package first
    case $PKG_MANAGER in
        apt)
            if apt-cache search easyeffects | grep -q "^easyeffects"; then
                echo -e "${INFO} Installing EasyEffects from native repository..."
                install_package "easyeffects" "$LOG_FILE"
                echo -e "${OK} EasyEffects installed successfully"
                return 0
            fi
            ;;
    esac
    
    # Fall back to Flatpak
    echo -e "${WARN} EasyEffects not available in native repositories"
    echo -e "${NOTE} Installing via Flatpak (sandboxed application)"
    
    if ! command -v flatpak &> /dev/null; then
        echo -e "${INFO} Installing Flatpak..."
        install_package "flatpak" "$LOG_FILE"
        echo -e "${INFO} Adding Flathub repository..."
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >> "$LOG_FILE" 2>&1
    fi
    
    echo -e "${INFO} Installing EasyEffects via Flatpak..."
    flatpak install -y flathub com.github.wwmm.easyeffects
    echo -e "${OK} EasyEffects installed successfully (via Flatpak)"
    echo -e "${NOTE} Launch with: ${CYAN}flatpak run com.github.wwmm.easyeffects${RESET}"
}

install_all_media() {
    print_section "Installing All Media Applications"
    
    local failed=0
    install_pipewire_rnnoise || ((failed++))
    install_spotify || ((failed++))
    install_vlc || ((failed++))
    install_obs || ((failed++))
    install_noisetorch || ((failed++))
    install_easyeffects || ((failed++))
    
    echo -e "\n${CYAN}════════════════════════════════════════${RESET}"
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ All media applications installed successfully!${RESET}"
    else
        echo -e "${YELLOW}${BOLD}⚠ $failed application(s) failed to install${RESET}"
    fi
    echo -e "${CYAN}════════════════════════════════════════${RESET}\n"
}

# ============================================================================
# MENU FUNCTIONS
# ============================================================================

show_main_menu() {
    echo -e "${BOLD}Application Categories:${RESET}\n"
    echo -e "  ${GREEN}1${RESET}) Browsers ${CYAN}(Chrome, Firefox, Brave, Edge)${RESET}"
    echo -e "  ${GREEN}2${RESET}) Communication ${CYAN}(Slack, Discord, Telegram, Zoom)${RESET}"
    echo -e "  ${GREEN}3${RESET}) Developer Tools ${CYAN}(VSCode, Cursor, Antigravity)${RESET}"
    echo -e "  ${GREEN}4${RESET}) Media ${CYAN}(Spotify, VLC, OBS, Noise Suppression)${RESET}"
    echo -e "  ${GREEN}5${RESET}) Back to Main Menu"
    echo ""
}

show_browsers_menu() {
    echo -e "${BOLD}Browsers:${RESET}\n"
    echo -e "  ${GREEN}1${RESET}) Google Chrome"
    echo -e "  ${GREEN}2${RESET}) Firefox"
    echo -e "  ${GREEN}3${RESET}) Brave"
    echo -e "  ${GREEN}4${RESET}) Microsoft Edge"
    echo -e "  ${GREEN}5${RESET}) Install All Browsers"
    echo -e "  ${GREEN}6${RESET}) Back"
    echo ""
}

show_communication_menu() {
    echo -e "${BOLD}Communication Tools:${RESET}\n"
    echo -e "  ${GREEN}1${RESET}) Slack"
    echo -e "  ${GREEN}2${RESET}) Discord"
    echo -e "  ${GREEN}3${RESET}) Telegram"
    echo -e "  ${GREEN}4${RESET}) Zoom"
    echo -e "  ${GREEN}5${RESET}) Install All Communication Tools"
    echo -e "  ${GREEN}6${RESET}) Back"
    echo ""
}

show_developer_menu() {
    echo -e "${BOLD}Developer Tools:${RESET}\n"
    echo -e "  ${GREEN}1${RESET}) Visual Studio Code"
    echo -e "  ${GREEN}2${RESET}) Cursor"
    echo -e "  ${GREEN}3${RESET}) Antigravity"
    echo -e "  ${GREEN}4${RESET}) Install All Developer Tools"
    echo -e "  ${GREEN}5${RESET}) Back"
    echo ""
}

show_media_menu() {
    echo -e "${BOLD}Media Applications:${RESET}\n"
    echo -e "  ${GREEN}1${RESET}) ${BOLD}PipeWire RNNoise${RESET} ${CYAN}(Built-in Noise Suppression - Recommended)${RESET}"
    echo -e "  ${GREEN}2${RESET}) Spotify"
    echo -e "  ${GREEN}3${RESET}) VLC Media Player"
    echo -e "  ${GREEN}4${RESET}) OBS Studio"
    echo -e "  ${GREEN}5${RESET}) NoiseTorch ${CYAN}(Alternative Noise Suppression)${RESET}"
    echo -e "  ${GREEN}6${RESET}) EasyEffects ${CYAN}(Audio Effects Suite)${RESET}"
    echo -e "  ${GREEN}7${RESET}) Install All Media Applications"
    echo -e "  ${GREEN}8${RESET}) Back"
    echo ""
}

# ============================================================================
# SUBMENU HANDLERS
# ============================================================================

browsers_menu() {
    while true; do
        show_applications_banner
        show_browsers_menu
        read -p "$(echo -e ${CYAN}Enter your choice [1-6]:${RESET} )" choice
        
        case $choice in
            1) install_google_chrome; read -p "Press Enter to continue..." ;;
            2) install_firefox; read -p "Press Enter to continue..." ;;
            3) install_brave; read -p "Press Enter to continue..." ;;
            4) install_edge; read -p "Press Enter to continue..." ;;
            5) install_all_browsers; read -p "Press Enter to continue..." ;;
            6) return 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${RESET}\n"; sleep 1 ;;
        esac
    done
}

communication_menu() {
    while true; do
        show_applications_banner
        show_communication_menu
        read -p "$(echo -e ${CYAN}Enter your choice [1-6]:${RESET} )" choice
        
        case $choice in
            1) install_slack; read -p "Press Enter to continue..." ;;
            2) install_discord; read -p "Press Enter to continue..." ;;
            3) install_telegram; read -p "Press Enter to continue..." ;;
            4) install_zoom; read -p "Press Enter to continue..." ;;
            5) install_all_communication; read -p "Press Enter to continue..." ;;
            6) return 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${RESET}\n"; sleep 1 ;;
        esac
    done
}

developer_tools_menu() {
    while true; do
        show_applications_banner
        show_developer_menu
        read -p "$(echo -e ${CYAN}Enter your choice [1-5]:${RESET} )" choice
        
        case $choice in
            1) install_vscode; read -p "Press Enter to continue..." ;;
            2) install_cursor; read -p "Press Enter to continue..." ;;
            3) install_antigravity; read -p "Press Enter to continue..." ;;
            4) install_all_developer_tools; read -p "Press Enter to continue..." ;;
            5) return 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${RESET}\n"; sleep 1 ;;
        esac
    done
}

media_menu() {
    while true; do
        show_applications_banner
        show_media_menu
        read -p "$(echo -e ${CYAN}Enter your choice [1-8]:${RESET} )" choice
        
        case $choice in
            1) install_pipewire_rnnoise; read -p "Press Enter to continue..." ;;
            2) install_spotify; read -p "Press Enter to continue..." ;;
            3) install_vlc; read -p "Press Enter to continue..." ;;
            4) install_obs; read -p "Press Enter to continue..." ;;
            5) install_noisetorch; read -p "Press Enter to continue..." ;;
            6) install_easyeffects; read -p "Press Enter to continue..." ;;
            7) install_all_media; read -p "Press Enter to continue..." ;;
            8) return 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${RESET}\n"; sleep 1 ;;
        esac
    done
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    show_applications_banner
    
    while true; do
        show_main_menu
        read -p "$(echo -e ${CYAN}Enter your choice [1-5]:${RESET} )" choice
        
        case $choice in
            1) browsers_menu ;;
            2) communication_menu ;;
            3) developer_tools_menu ;;
            4) media_menu ;;
            5)
                echo -e "\n${CYAN}Returning to main menu...${RESET}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${RESET}\n"
                sleep 1
                show_applications_banner
                ;;
        esac
    done
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
