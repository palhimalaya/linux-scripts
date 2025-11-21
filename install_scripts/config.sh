#!/bin/bash
# Configuration Management Script
# Symlinks configuration files from assets to ~/.config
# Author: palhimalaya

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/Global_functions.sh"

ASSETS_CONFIG_DIR="$(dirname "$SCRIPT_DIR")/assets/config"
USER_CONFIG_DIR="$HOME/.config"
LOG_FILE="$LOG_DIR/config-$(date +%Y%m%d-%H%M%S).log"

# ============================================================================
# BANNER
# ============================================================================

show_config_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              Configuration Management                      ║"
    echo "║                      by palhimalaya                        ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}\n"
}

# ============================================================================
# FUNCTIONS
# ============================================================================

link_config() {
    local app_name=$1
    local source_path="$ASSETS_CONFIG_DIR/$app_name"
    local target_path="$USER_CONFIG_DIR/$app_name"
    
    print_section "Configuring $app_name"
    
    if [ ! -d "$source_path" ]; then
        echo -e "${ERROR} Configuration for $app_name not found in assets"
        return 1
    fi
    
    # Check if target exists
    if [ -e "$target_path" ]; then
        if [ -L "$target_path" ]; then
            # It's already a symlink
            local current_target=$(readlink -f "$target_path")
            local expected_source=$(readlink -f "$source_path")
            
            if [ "$current_target" == "$expected_source" ]; then
                echo -e "${INFO} $app_name is already correctly linked"
                return 0
            else
                echo -e "${WARN} $app_name is linked to $current_target"
                echo -e "${NOTE} Updating link to $expected_source"
                rm "$target_path"
            fi
        else
            # It's a real directory/file
            echo -e "${WARN} Existing configuration found for $app_name"
            echo -e "${INFO} Backing up existing configuration..."
            mv "$target_path" "${target_path}.backup-$(date +%Y%m%d-%H%M%S)"
            echo -e "${OK} Backup created"
        fi
    fi
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$target_path")"
    
    # Create symlink
    echo -e "${INFO} Linking $app_name configuration..."
    ln -s "$source_path" "$target_path"
    
    if [ -L "$target_path" ]; then
        echo -e "${OK} $app_name configured successfully"
    else
        echo -e "${ERROR} Failed to link $app_name"
        return 1
    fi
}

install_all_configs() {
    print_section "Installing All Configurations"
    
    # Get list of directories in assets/config
    local configs=($(ls -d "$ASSETS_CONFIG_DIR"/*/ | xargs -n 1 basename))
    
    if [ ${#configs[@]} -eq 0 ]; then
        echo -e "${WARN} No configurations found in assets/config"
        return 0
    fi
    
    local failed=0
    
    for config in "${configs[@]}"; do
        link_config "$config" || ((failed++))
    done
    
    echo -e "\n${CYAN}════════════════════════════════════════${RESET}"
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ All configurations linked successfully!${RESET}"
    else
        echo -e "${YELLOW}${BOLD}⚠ $failed configuration(s) failed to link${RESET}"
    fi
    echo -e "${CYAN}════════════════════════════════════════${RESET}\n"
}

# ============================================================================
# MENU
# ============================================================================

show_config_menu() {
    echo -e "${BOLD}Configuration Options:${RESET}\n"
    
    # Dynamically list available configs
    local configs=($(ls -d "$ASSETS_CONFIG_DIR"/*/ 2>/dev/null | xargs -n 1 basename))
    local i=1
    
    for config in "${configs[@]}"; do
        echo -e "  ${GREEN}$i${RESET}) Link ${CYAN}$config${RESET}"
        ((i++))
    done
    
    echo -e "  ${GREEN}$i${RESET}) Link All Configurations"
    ((i++))
    echo -e "  ${GREEN}$i${RESET}) Back to Main Menu"
    echo ""
}

main() {
    show_config_banner
    
    # Ensure config directory exists
    mkdir -p "$USER_CONFIG_DIR"
    
    while true; do
        show_config_menu
        
        local configs=($(ls -d "$ASSETS_CONFIG_DIR"/*/ 2>/dev/null | xargs -n 1 basename))
        local total_configs=${#configs[@]}
        local all_option=$((total_configs + 1))
        local back_option=$((total_configs + 2))
        
        read -p "$(echo -e ${CYAN}Enter your choice [1-$back_option]:${RESET} )" choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if [ "$choice" -ge 1 ] && [ "$choice" -le "$total_configs" ]; then
                local index=$((choice - 1))
                link_config "${configs[$index]}"
                read -p "Press Enter to continue..."
                show_config_banner
            elif [ "$choice" -eq "$all_option" ]; then
                install_all_configs
                read -p "Press Enter to continue..."
                show_config_banner
            elif [ "$choice" -eq "$back_option" ]; then
                echo -e "\n${CYAN}Returning to main menu...${RESET}\n"
                exit 0
            else
                echo -e "${RED}Invalid option. Please try again.${RESET}\n"
                sleep 1
                show_config_banner
            fi
        else
            echo -e "${RED}Invalid input. Please enter a number.${RESET}\n"
            sleep 1
            show_config_banner
        fi
    done
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
