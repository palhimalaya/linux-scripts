#!/bin/bash
# Webapp setup for DankMaterialShell
# Copies webapp scripts to ~/.config/DankMaterialShell/scripts/webapp
# Installs dependencies and creates a launcher entry.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/webapp"
TARGET_DIR="$HOME/.config/DankMaterialShell/scripts/webapp"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/webapp-installer.desktop"

# ------------------------------
# Basic logging helpers
# ------------------------------
info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
error() { echo "[ERROR] $*"; }

# ------------------------------
# Package manager detection
# ------------------------------
get_pkg_manager() {
    if command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    else
        echo "unknown"
    fi
}

install_packages() {
    local pkg_manager=$1
    shift
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi

    case "$pkg_manager" in
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
        pacman)
            sudo pacman -S --noconfirm "${packages[@]}"
            ;;
        apt)
            sudo apt-get update -y
            sudo apt-get install -y "${packages[@]}"
            ;;
        *)
            error "Unsupported package manager. Install manually: ${packages[*]}"
            return 1
            ;;
    esac
}

# ------------------------------
# Prompt helpers (gum if present)
# ------------------------------
has_gum() {
    command -v gum >/dev/null 2>&1
}

prompt_choice() {
    local prompt=$1
    shift
    local options=("$@")

    if has_gum; then
        gum choose --header "$prompt" "${options[@]}"
    else
        echo "$prompt"
        select opt in "${options[@]}"; do
            if [ -n "${opt:-}" ]; then
                echo "$opt"
                break
            fi
        done
    fi
}

prompt_input() {
    local prompt=$1

    if has_gum; then
        gum input --placeholder "$prompt"
    else
        read -r -p "$prompt" value
        echo "$value"
    fi
}

# ------------------------------
# Dependency installation
# ------------------------------
ensure_dependencies() {
    local pkg_manager
    pkg_manager=$(get_pkg_manager)

    local missing=()

    if ! command -v jq >/dev/null 2>&1; then
        missing+=("jq")
    fi
    if ! command -v xdg-settings >/dev/null 2>&1; then
        missing+=("xdg-utils")
    fi
    if ! command -v gum >/dev/null 2>&1; then
        missing+=("gum")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        info "Installing missing dependencies: ${missing[*]}"
        install_packages "$pkg_manager" "${missing[@]}"
    else
        info "All dependencies are already installed."
    fi
}

# ------------------------------
# Copy/update scripts with prompt
# ------------------------------
copy_with_prompt() {
    local src=$1
    local dest=$2

    if [ -e "$dest" ]; then
        local choice
        choice=$(prompt_choice "File exists: $dest" "skip" "replace")
        case "$choice" in
            skip)
                info "Skipping $dest"
                return 0
                ;;
            replace)
                cp -a "$src" "$dest"
                info "Replaced $dest"
                return 0
                ;;
            *)
                warn "Unknown choice; skipping $dest"
                return 0
                ;;
        esac
    else
        cp -a "$src" "$dest"
        info "Copied $dest"
    fi
}

copy_webapp_files() {
    if [ ! -d "$SOURCE_DIR" ]; then
        error "Source directory not found: $SOURCE_DIR"
        return 1
    fi

    mkdir -p "$TARGET_DIR"

    # Copy top-level files
    while IFS= read -r -d '' item; do
        local rel
        rel="${item#$SOURCE_DIR/}"
        local target_path="$TARGET_DIR/$rel"
        local target_parent
        target_parent="$(dirname "$target_path")"
        mkdir -p "$target_parent"
        copy_with_prompt "$item" "$target_path"
    done < <(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -print0)

    # Copy subdirectories (icons, etc.) recursively with prompts per file
    while IFS= read -r -d '' item; do
        local rel
        rel="${item#$SOURCE_DIR/}"
        local target_path="$TARGET_DIR/$rel"
        local target_parent
        target_parent="$(dirname "$target_path")"
        mkdir -p "$target_parent"
        copy_with_prompt "$item" "$target_path"
    done < <(find "$SOURCE_DIR" -mindepth 2 -print0)
}

ensure_executable_scripts() {
    # Set executable bit for scripts in the target root
    find "$TARGET_DIR" -maxdepth 1 -type f \( ! -name "README.md" \) -exec chmod +x {} \;
}

# ------------------------------
# Shell PATH integration
# ------------------------------
add_webapp_path_to_shell() {
    local export_line='export PATH="$HOME/.config/DankMaterialShell/scripts/webapp:$PATH"'
    local marker='# create web app'

    local shell_rc=""
    if [ -n "${ZSH_VERSION:-}" ] || [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ] || [ -f "$HOME/.bashrc" ]; then
        shell_rc="$HOME/.bashrc"
    else
        warn "No .zshrc or .bashrc found. Skipping PATH setup."
        return 0
    fi

    if grep -Fq "$export_line" "$shell_rc" 2>/dev/null; then
        info "Webapp PATH already set in $shell_rc"
        return 0
    fi

    {
        echo ""
        echo "$marker"
        echo "$export_line"
    } >> "$shell_rc"

    info "Added webapp PATH to $shell_rc"
}

# ------------------------------
# Desktop integration
# ------------------------------
create_desktop_entry() {
    mkdir -p "$DESKTOP_DIR"

    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Webapp Installer
Comment=Install and manage webapps
Exec=$HOME/.config/DankMaterialShell/scripts/webapp/webapp-install
Terminal=true
Categories=Utility;
EOF

    info "Created desktop entry: $DESKTOP_FILE"
}

# ------------------------------
# Browser detection
# ------------------------------
ensure_default_browser() {
    local current
    current=$(xdg-settings get default-web-browser 2>/dev/null || true)

    if [ -z "$current" ] || [ "$current" = "" ] || [ "$current" = "null" ]; then
        warn "No default browser detected."
        local browser
        browser=$(prompt_input "Enter the default browser desktop file (e.g. firefox.desktop): ")
        if [ -n "$browser" ]; then
            xdg-settings set default-web-browser "$browser"
            info "Default browser set to: $browser"
        else
            warn "No browser set. You can set it later with: xdg-settings set default-web-browser <file>."
        fi
    else
        info "Default browser detected: $current"
    fi
}

# ------------------------------
# Main
# ------------------------------
main() {
    info "Starting webapp setup..."

    ensure_dependencies

    mkdir -p "$TARGET_DIR"
    copy_webapp_files
    ensure_executable_scripts
    add_webapp_path_to_shell

    create_desktop_entry
    ensure_default_browser

    info "Webapp setup complete."
}

main "$@"
