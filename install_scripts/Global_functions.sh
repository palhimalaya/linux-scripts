#!/bin/bash
# Global Functions and Utilities for Installation Scripts

set -e

# ============================================================================
# COLOR DEFINITIONS
# ============================================================================
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
ACTION="$(tput setaf 6)[ACTION]$(tput sgr0)"

MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
CYAN="$(tput setaf 6)"
RED="$(tput setaf 1)"
RESET="$(tput sgr0)"

# ============================================================================
# LOGGING SETUP
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PARENT_DIR/Install-Logs"

# Create log directory if it doesn't exist
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

# ============================================================================
# PACKAGE MANAGER DETECTION
# ============================================================================
detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    else
        echo "unknown"
    fi
}

# Export package manager for use in other scripts
export PKG_MANAGER=$(detect_package_manager)

# ============================================================================
# PROGRESS ANIMATION
# ============================================================================
show_progress() {
    local pid=$1
    local package_name=$2
    local spin_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0

    tput civis  # Hide cursor
    printf "\r${INFO} Installing ${YELLOW}%s${RESET} ..." "$package_name"

    while ps -p $pid &> /dev/null; do
        printf "\r${INFO} Installing ${YELLOW}%s${RESET} %s " "$package_name" "${spin_chars[i]}"
        i=$(( (i + 1) % 10 ))
        sleep 0.1
    done

    printf "\r${OK} Package ${YELLOW}%s${RESET} installed successfully!%-20s\n" "$package_name" ""
    tput cnorm  # Show cursor
}

# ============================================================================
# PACKAGE INSTALLATION FUNCTIONS
# ============================================================================

# Check if package is installed
is_package_installed() {
    local package=$1
    
    case $PKG_MANAGER in
        apt)
            # Check for package with or without architecture suffix (e.g., package:amd64)
            dpkg -l | grep -q "^ii  $package\(:\|[[:space:]]\)" 2>/dev/null
            ;;
        dnf|yum)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        pacman)
            pacman -Q "$package" >/dev/null 2>&1
            ;;
        zypper)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        apk)
            apk info -e "$package" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# Install package with progress animation
install_package() {
    local package=$1
    local log_file=${2:-"$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"}
    
    # Check if already installed
    if is_package_installed "$package"; then
        echo -e "${INFO} ${MAGENTA}$package${RESET} is already installed. Skipping..."
        return 0
    fi
    
    # Install based on package manager
    case $PKG_MANAGER in
        apt)
            (
                stdbuf -oL sudo apt-get install -y "$package" 2>&1
            ) >> "$log_file" 2>&1 &
            ;;
        dnf)
            (
                stdbuf -oL sudo dnf install -y "$package" 2>&1
            ) >> "$log_file" 2>&1 &
            ;;
        yum)
            (
                stdbuf -oL sudo yum install -y "$package" 2>&1
            ) >> "$log_file" 2>&1 &
            ;;
        pacman)
            (
                stdbuf -oL sudo pacman -S --noconfirm "$package" 2>&1
            ) >> "$log_file" 2>&1 &
            ;;
        zypper)
            (
                stdbuf -oL sudo zypper install -y "$package" 2>&1
            ) >> "$log_file" 2>&1 &
            ;;
        apk)
            (
                stdbuf -oL sudo apk add "$package" 2>&1
            ) >> "$log_file" 2>&1 &
            ;;
        *)
            echo -e "${ERROR} Unknown package manager. Cannot install $package"
            return 1
            ;;
    esac
    
    local PID=$!
    show_progress $PID "$package"
    wait $PID
    
    # Verify installation
    if is_package_installed "$package"; then
        return 0
    else
        echo -e "\e[1A\e[K${ERROR} ${YELLOW}$package${RESET} failed to install. Check log: $log_file"
        return 1
    fi
}

# Update package database
update_package_database() {
    local log_file=${1:-"$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"}
    
    echo -e "${NOTE} Updating package database..."
    
    case $PKG_MANAGER in
        apt)
            sudo apt-get update >> "$log_file" 2>&1
            ;;
        dnf)
            sudo dnf check-update >> "$log_file" 2>&1 || true
            ;;
        yum)
            sudo yum check-update >> "$log_file" 2>&1 || true
            ;;
        pacman)
            sudo pacman -Sy >> "$log_file" 2>&1
            ;;
        zypper)
            sudo zypper refresh >> "$log_file" 2>&1
            ;;
        apk)
            sudo apk update >> "$log_file" 2>&1
            ;;
    esac
    
    echo -e "${OK} Package database updated"
}

# Reinstall package
reinstall_package() {
    local package=$1
    local log_file=${2:-"$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"}
    
    case $PKG_MANAGER in
        apt)
            (
                stdbuf -oL sudo apt-get install --reinstall -y "$package" 2>&1
            ) >> "$log_file" 2>&1 &
            ;;
        dnf)
            (
                stdbuf -oL sudo dnf reinstall -y "$package" 2>&1
            ) >> "$log_file" 2>&1 &
            ;;
        yum)
            (
                stdbuf -oL sudo yum reinstall -y "$package" 2>&1
            ) >> "$log_file" 2>&1 &
            ;;
        pacman)
            (
                stdbuf -oL sudo pacman -S --noconfirm "$package" 2>&1
            ) >> "$log_file" 2>&1 &
            ;;
        *)
            echo -e "${ERROR} Reinstall not supported for $PKG_MANAGER"
            return 1
            ;;
    esac
    
    local PID=$!
    show_progress $PID "$package"
    wait $PID
    
    if is_package_installed "$package"; then
        echo -e "\e[1A\e[K${OK} Package ${YELLOW}$package${RESET} reinstalled successfully!"
        return 0
    else
        echo -e "\e[1A\e[K${ERROR} ${YELLOW}$package${RESET} failed to reinstall"
        return 1
    fi
}

# Uninstall package
uninstall_package() {
    local package=$1
    local log_file=${2:-"$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"}
    
    if ! is_package_installed "$package"; then
        echo -e "${INFO} Package ${MAGENTA}$package${RESET} not installed, skipping."
        return 0
    fi
    
    echo -e "${NOTE} Removing ${MAGENTA}$package${RESET}..."
    
    case $PKG_MANAGER in
        apt)
            sudo apt-get autoremove -y "$package" >> "$log_file" 2>&1
            ;;
        dnf)
            sudo dnf remove -y "$package" >> "$log_file" 2>&1
            ;;
        yum)
            sudo yum remove -y "$package" >> "$log_file" 2>&1
            ;;
        pacman)
            sudo pacman -R --noconfirm "$package" >> "$log_file" 2>&1
            ;;
        zypper)
            sudo zypper remove -y "$package" >> "$log_file" 2>&1
            ;;
        apk)
            sudo apk del "$package" >> "$log_file" 2>&1
            ;;
    esac
    
    if ! is_package_installed "$package"; then
        echo -e "${OK} ${MAGENTA}$package${RESET} removed successfully"
        return 0
    else
        echo -e "${ERROR} Failed to remove $package"
        return 1
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Print section header
print_section() {
    local title=$1
    echo ""
    echo "========================================"
    echo "  $title"
    echo "========================================"
    echo ""
}

# Download file with retry
download_with_retry() {
    local url=$1
    local output=$2
    local max_attempts=${3:-3}
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo -e "${INFO} Downloading (attempt $attempt/$max_attempts)..."
        if curl -fsSL -o "$output" "$url"; then
            echo -e "${OK} Download successful"
            return 0
        fi
        echo -e "${WARN} Download failed, retrying in 2 seconds..."
        sleep 2
        ((attempt++))
    done
    
    echo -e "${ERROR} Failed to download after $max_attempts attempts"
    return 1
}

# Create backup of file
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        local backup="${file}-backup-$(date +%Y%m%d-%H%M%S)"
        cp "$file" "$backup"
        echo -e "${INFO} Backed up $file to $backup"
    fi
}