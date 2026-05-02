#!/bin/bash
# Main Installation Script
# Orchestrates installation of various components
# Author: palhimalaya

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPTS_DIR="$SCRIPT_DIR/install_scripts"

# Colors
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'

# ============================================================================
# BANNER
# ============================================================================

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              System Installation Script                    ║"
    echo "║                      by palhimalaya                        ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}\n"
}

# ============================================================================
# MENU FUNCTIONS
# ============================================================================

show_menu() {
    echo -e "${BOLD}Available Options:${RESET}\n"
    echo -e "  ${GREEN}1${RESET}) Install Zsh with Oh My Zsh"
    echo -e "  ${GREEN}2${RESET}) Install Fonts (System + Nerd Fonts)"
    echo -e "  ${GREEN}3${RESET}) ${MAGENTA}Developer Tools Menu${RESET} (asdf, Node.js, Ruby, PostgreSQL, MySQL)"
    echo -e "  ${GREEN}4${RESET}) ${BLUE}Applications Menu${RESET} (Browsers, Communication, IDEs, Media)"
    echo -e "  ${GREEN}5${RESET}) ${MAGENTA}Install Dotfiles${RESET} (Symlink configurations)"
    echo -e "  ${GREEN}6${RESET}) ${YELLOW}Backup System Configuration${RESET}"
    echo -e "  ${GREEN}7${RESET}) Install All ${CYAN}(Zsh + Fonts)${RESET}"
    echo -e "  ${GREEN}8${RESET}) Setup Webapp Scripts"
    echo -e "  ${GREEN}9${RESET}) Exit"
    echo ""
}

run_script() {
    local script_name=$1
    local script_path="$INSTALL_SCRIPTS_DIR/$script_name"
    
    if [ ! -f "$script_path" ]; then
        echo -e "${RED}[ERROR]${RESET} Script not found: $script_path"
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        chmod +x "$script_path"
    fi
    
    echo -e "\n${CYAN}════════════════════════════════════════${RESET}"
    echo -e "${YELLOW}Running: $script_name${RESET}"
    echo -e "${CYAN}════════════════════════════════════════${RESET}\n"
    
    bash "$script_path"
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo -e "\n${GREEN}✓ $script_name completed successfully${RESET}\n"
    else
        echo -e "\n${RED}✗ $script_name failed with exit code $exit_code${RESET}\n"
    fi
    
    return $exit_code
}

install_zsh() {
    run_script "zsh.sh"
}

install_fonts() {
    run_script "fonts.sh"
}

backup_system() {
    run_script "backup.sh"
}

open_developer_menu() {
    run_script "developer_tools.sh"
}

open_applications_menu() {
    run_script "applications.sh"
}

open_config_menu() {
    run_script "config.sh"
}

setup_webapp_scripts() {
    run_script "webapp_setup.sh"
}

install_all() {
    echo -e "${BOLD}${CYAN}Installing Zsh and Fonts...${RESET}\n"
    echo -e "${NOTE} This will install: Zsh with Oh My Zsh + Fonts\n"
    echo -e "${NOTE} For developer tools, use option 3 (Developer Tools Menu)\n"
    
    # Prompt for backup
    echo -e "${YELLOW}Would you like to backup your current system configuration first?${RESET}"
    echo -e "${NOTE} This is recommended before making system changes."
    read -p "$(echo -e ${CYAN}Create backup? [y/N]:${RESET} )" -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\n${INFO} Creating backup before installation...\n"
        backup_system
        echo -e "\n${OK} Backup completed. Proceeding with installations...\n"
        read -p "Press Enter to continue..."
    else
        echo -e "${INFO} Skipping backup. Proceeding with installations...\n"
    fi
    
    local failed=0
    
    install_fonts || ((failed++))
    install_zsh || ((failed++))
    
    echo -e "\n${CYAN}════════════════════════════════════════${RESET}"
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ All installations completed successfully!${RESET}"
    else
        echo -e "${YELLOW}${BOLD}⚠ $failed installation(s) failed${RESET}"
    fi
    echo -e "${CYAN}════════════════════════════════════════${RESET}\n"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    show_banner
    
    # Check if install_scripts directory exists
    if [ ! -d "$INSTALL_SCRIPTS_DIR" ]; then
        echo -e "${RED}[ERROR]${RESET} Install scripts directory not found: $INSTALL_SCRIPTS_DIR"
        exit 1
    fi
    
    # Interactive mode if no arguments
    if [ $# -eq 0 ]; then
        while true; do
            show_menu
            read -p "$(echo -e ${CYAN}Enter your choice [1-9]:${RESET} )" choice
            
            case $choice in
                1)
                    install_zsh
                    read -p "Press Enter to continue..."
                    show_banner
                    ;;
                2)
                    install_fonts
                    read -p "Press Enter to continue..."
                    show_banner
                    ;;
                3)
                    open_developer_menu
                    show_banner
                    ;;
                4)
                    open_applications_menu
                    show_banner
                    ;;
                5)
                    open_config_menu
                    show_banner
                    ;;
                6)
                    backup_system
                    read -p "Press Enter to continue..."
                    show_banner
                    ;;
                7)
                    install_all
                    read -p "Press Enter to continue..."
                    show_banner
                    ;;
                8)
                    setup_webapp_scripts
                    read -p "Press Enter to continue..."
                    show_banner
                    ;;
                9)
                    echo -e "\n${CYAN}Goodbye!${RESET}\n"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Invalid option. Please try again.${RESET}\n"
                    sleep 1
                    show_banner
                    ;;
            esac
        done
    fi
    
    # Command line mode
    case "$1" in
        zsh)
            install_zsh
            ;;
        fonts)
            install_fonts
            ;;
        dev|developer)
            open_developer_menu
            ;;
        apps|applications)
            open_applications_menu
            ;;
        config|dotfiles)
            open_config_menu
            ;;
        backup)
            backup_system
            ;;
        all)
            install_all
            ;;
        --help|-h)
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  zsh         Install Zsh with Oh My Zsh"
            echo "  fonts       Install fonts"
            echo "  dev         Open developer tools menu"
            echo "  dev         Open developer tools menu"
            echo "  apps        Open applications menu"
            echo "  config      Open configuration/dotfiles menu"
            echo "  backup      Backup current system configuration"
            echo "  all         Install all components (prompts for backup first)"
            echo "  --help      Show this help message"
            echo ""
            echo "If no option is provided, interactive menu will be shown."
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
