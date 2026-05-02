#!/bin/bash
# Developer Tools Installation Script
# Installs asdf and various development tools (PostgreSQL, MySQL, Node.js, Ruby)
# Author: palhimalaya

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/Global_functions.sh"

LOG_FILE="$LOG_DIR/developer-tools-$(date +%Y%m%d-%H%M%S).log"

# asdf configuration
ASDF_DIR="$HOME/.asdf"
ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"

# ============================================================================
# BANNER
# ============================================================================

show_dev_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              Developer Tools Installation                  ║"
    echo "║                      by palhimalaya                        ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}\n"
}

# ============================================================================
# ASDF INSTALLATION
# ============================================================================

install_asdf_dependencies() {
    print_section "Installing asdf Dependencies"
    
    case $PKG_MANAGER in
        apt)
            local packages=(
                "curl"
                "git"
                "build-essential"
                "libssl-dev"
                "libreadline-dev"
                "zlib1g-dev"
                "libncurses-dev"
                "libffi-dev"
                "libgdbm-dev"
                "libyaml-dev"
                "libsqlite3-dev"
                "libbz2-dev"
            )
            ;;
        dnf|yum)
            local packages=(
                "curl"
                "git"
                "gcc"
                "make"
                "openssl-devel"
                "readline-devel"
                "zlib-devel"
                "ncurses-devel"
                "libffi-devel"
                "gdbm-devel"
                "libyaml-devel"
                "sqlite-devel"
                "bzip2-devel"
            )
            ;;
        pacman)
            local packages=(
                "curl"
                "git"
                "base-devel"
                "openssl"
                "readline"
                "zlib"
                "ncurses"
                "libffi"
                "gdbm"
                "libyaml"
                "sqlite"
                "bzip2"
            )
            ;;
        *)
            echo -e "${WARN} Unknown package manager. Please install dependencies manually."
            return 1
            ;;
    esac
    
    update_package_database "$LOG_FILE"
    
    for package in "${packages[@]}"; do
        install_package "$package" "$LOG_FILE"
    done
}

install_asdf() {
    print_section "Installing asdf Version Manager"
    
    if [ -d "$ASDF_DIR" ]; then
        echo -e "${INFO} asdf is already installed at $ASDF_DIR"
        read -p "$(echo -e ${YELLOW}Reinstall asdf? [y/N]:${RESET} )" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${INFO} Skipping asdf installation"
            return 0
        fi
        echo -e "${NOTE} Removing existing asdf installation..."
        rm -rf "$ASDF_DIR"
    fi
    
    # Install dependencies
    install_asdf_dependencies
    
    # Clone asdf repository
    echo -e "${INFO} Cloning asdf repository..."
    if git clone https://github.com/asdf-vm/asdf.git "$ASDF_DIR" --branch v0.14.0 >> "$LOG_FILE" 2>&1; then
        echo -e "${OK} asdf cloned successfully"
    else
        echo -e "${ERROR} Failed to clone asdf repository"
        return 1
    fi
    
    # Add asdf to shell configuration
    configure_asdf_shell
    
    # Source asdf for current session
    source "$ASDF_DIR/asdf.sh"
    
    echo -e "${OK} asdf installed successfully!"
    echo -e "${NOTE} Please restart your shell or run: ${CYAN}source ~/.zshrc${RESET} (or ~/.bashrc)"
}

configure_asdf_shell() {
    echo -e "${INFO} Configuring shell integration..."
    
    # Detect shell
    local shell_rc=""
    if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ] || [ -f "$HOME/.bashrc" ]; then
        shell_rc="$HOME/.bashrc"
    else
        echo -e "${WARN} Could not detect shell configuration file"
        return 1
    fi
    
    # Check if asdf is already configured
    if grep -q "asdf.sh" "$shell_rc" 2>/dev/null; then
        echo -e "${INFO} asdf already configured in $shell_rc"
        return 0
    fi
    
    # Add asdf configuration
    echo -e "${NOTE} Adding asdf to $shell_rc..."
    cat >> "$shell_rc" << 'EOF'

# asdf version manager
. "$HOME/.asdf/asdf.sh"
EOF
    
    # Add completions for zsh
    if [[ "$shell_rc" == *"zshrc"* ]]; then
        if ! grep -q "asdf.sh" "$HOME/.zshrc" 2>/dev/null; then
            echo '. "$HOME/.asdf/completions/asdf.bash"' >> "$shell_rc"
        fi
    fi
    
    echo -e "${OK} Shell configuration updated"
}

# ============================================================================
# PLUGIN INSTALLATION HELPERS
# ============================================================================

ensure_asdf_loaded() {
    if ! command -v asdf &> /dev/null; then
        if [ -f "$ASDF_DIR/asdf.sh" ]; then
            source "$ASDF_DIR/asdf.sh"
        else
            echo -e "${ERROR} asdf is not installed. Please install asdf first."
            return 1
        fi
    fi
}

install_asdf_plugin() {
    local plugin_name=$1
    
    ensure_asdf_loaded || return 1
    
    echo -e "${INFO} Adding asdf plugin: ${YELLOW}$plugin_name${RESET}"
    
    if asdf plugin list | grep -q "^$plugin_name$"; then
        echo -e "${INFO} Plugin ${YELLOW}$plugin_name${RESET} already added"
    else
        if asdf plugin add "$plugin_name" >> "$LOG_FILE" 2>&1; then
            echo -e "${OK} Plugin ${YELLOW}$plugin_name${RESET} added successfully"
        else
            echo -e "${ERROR} Failed to add plugin $plugin_name"
            return 1
        fi
    fi
}

install_tool_version() {
    local tool=$1
    local version=${2:-"latest"}
    
    ensure_asdf_loaded || return 1
    
    echo -e "${INFO} Installing ${YELLOW}$tool${RESET} version ${CYAN}$version${RESET}..."
    
    if asdf install "$tool" "$version" >> "$LOG_FILE" 2>&1; then
        echo -e "${OK} ${YELLOW}$tool${RESET} ${CYAN}$version${RESET} installed successfully"
        
        # Set as global version (prefer modern asdf syntax when available)
        if asdf set -u "$tool" "$version" >> "$LOG_FILE" 2>&1; then
            echo -e "${OK} Set ${YELLOW}$tool${RESET} ${CYAN}$version${RESET} as global version"
        else
            asdf global "$tool" "$version" >> "$LOG_FILE" 2>&1
            echo -e "${OK} Set ${YELLOW}$tool${RESET} ${CYAN}$version${RESET} as global version"
        fi
        return 0
    else
        echo -e "${ERROR} Failed to install $tool $version"
        return 1
    fi
}

# ============================================================================
# INDIVIDUAL TOOL INSTALLATIONS
# ============================================================================

install_nodejs() {
    print_section "Installing Node.js via asdf"
    
    install_asdf_plugin "nodejs"
    
    echo -e "${NOTE} Available Node.js versions (showing latest LTS and current):"
    asdf list all nodejs | grep -E "^(18|20|21|22)" | tail -5
    
    read -p "$(echo -e ${CYAN}Enter version to install [latest]:${RESET} )" version
    version=${version:-latest}
    
    install_tool_version "nodejs" "$version"
}

install_ruby() {
    print_section "Installing Ruby via asdf"
    
    # Install Ruby dependencies
    case $PKG_MANAGER in
        apt)
            install_package "autoconf" "$LOG_FILE"
            install_package "bison" "$LOG_FILE"
            install_package "patch" "$LOG_FILE"
            install_package "rustc" "$LOG_FILE"
            ;;
        dnf|yum)
            local packages=(
                "gcc"
                "make"
                "patch"
                "rust"
                "openssl-devel"
                "readline-devel"
                "zlib-devel"
                "libyaml-devel"
                "libffi-devel"
                "gdbm-devel"
                "ncurses-devel"
                "libxml2-devel"
                "libxslt-devel"
                "autoconf"
                "bison"
            )

            for package in "${packages[@]}"; do
                if [[ "$package" == "zlib-devel" ]]; then
                    if is_package_installed "zlib-ng-compat-devel"; then
                        echo -e "${INFO} ${MAGENTA}zlib-ng-compat-devel${RESET} is already installed. Skipping zlib-devel."
                        continue
                    fi

                    if ! install_package "zlib-devel" "$LOG_FILE"; then
                        echo -e "${WARN} zlib-devel not available. Trying zlib-ng-compat-devel instead."
                        install_package "zlib-ng-compat-devel" "$LOG_FILE"
                    fi
                    continue
                fi

                install_package "$package" "$LOG_FILE"
            done
            ;;
    esac
    
    install_asdf_plugin "ruby"
    
    echo -e "${NOTE} Available Ruby versions (showing latest stable):"
    asdf list all ruby | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | tail -5
    
    read -p "$(echo -e ${CYAN}Enter version to install [latest]:${RESET} )" version
    version=${version:-latest}
    
    install_tool_version "ruby" "$version"
}

install_postgres() {
    print_section "Installing PostgreSQL"
    
    case $PKG_MANAGER in
        apt)
            echo -e "${INFO} Installing PostgreSQL and related packages..."
            install_package "postgresql" "$LOG_FILE"
            install_package "postgresql-contrib" "$LOG_FILE"
            install_package "libpq-dev" "$LOG_FILE"
            
            echo -e "${INFO} Enabling and starting PostgreSQL service..."
            sudo systemctl enable --now postgresql >> "$LOG_FILE" 2>&1 || true
            
            echo -e "${OK} PostgreSQL installed successfully"
            echo -e "${NOTE} PostgreSQL service management:"
            echo -e "  Start:   ${CYAN}sudo systemctl start postgresql${RESET}"
            echo -e "  Enable:  ${CYAN}sudo systemctl enable postgresql${RESET}"
            echo -e "  Status:  ${CYAN}sudo systemctl status postgresql${RESET}"
            echo -e "${NOTE} Access PostgreSQL: ${CYAN}sudo -u postgres psql${RESET}"
            ;;
        dnf|yum)
            echo -e "${INFO} Installing PostgreSQL and related packages..."
            install_package "postgresql-server" "$LOG_FILE"
            install_package "postgresql-contrib" "$LOG_FILE"
            if is_package_installed "postgresql-private-devel"; then
                echo -e "${INFO} ${MAGENTA}postgresql-private-devel${RESET} is already installed. Skipping postgresql-devel."
            elif ! install_package "postgresql-devel" "$LOG_FILE"; then
                echo -e "${WARN} postgresql-devel not available. Trying postgresql-private-devel instead."
                install_package "postgresql-private-devel" "$LOG_FILE"
            fi
            
            # Initialize database
            echo -e "${INFO} Initializing PostgreSQL database..."
            sudo postgresql-setup --initdb >> "$LOG_FILE" 2>&1 || true
            
            echo -e "${INFO} Enabling and starting PostgreSQL service..."
            sudo systemctl enable --now postgresql >> "$LOG_FILE" 2>&1 || true
            
            echo -e "${OK} PostgreSQL installed successfully"
            echo -e "${NOTE} PostgreSQL service management:"
            echo -e "  Start:   ${CYAN}sudo systemctl start postgresql${RESET}"
            echo -e "  Enable:  ${CYAN}sudo systemctl enable postgresql${RESET}"
            echo -e "  Status:  ${CYAN}sudo systemctl status postgresql${RESET}"
            echo -e "${NOTE} Access PostgreSQL: ${CYAN}sudo -u postgres psql${RESET}"
            ;;
        pacman)
            echo -e "${INFO} Installing PostgreSQL and related packages..."
            install_package "postgresql" "$LOG_FILE"
            
            # Initialize database
            echo -e "${INFO} Initializing PostgreSQL database..."
            sudo -u postgres initdb -D /var/lib/postgres/data >> "$LOG_FILE" 2>&1 || true
            
            echo -e "${INFO} Enabling and starting PostgreSQL service..."
            sudo systemctl enable --now postgresql >> "$LOG_FILE" 2>&1 || true
            
            echo -e "${OK} PostgreSQL installed successfully"
            echo -e "${NOTE} PostgreSQL service management:"
            echo -e "  Start:   ${CYAN}sudo systemctl start postgresql${RESET}"
            echo -e "  Enable:  ${CYAN}sudo systemctl enable postgresql${RESET}"
            echo -e "  Status:  ${CYAN}sudo systemctl status postgresql${RESET}"
            echo -e "${NOTE} Access PostgreSQL: ${CYAN}sudo -u postgres psql${RESET}"
            ;;
        *)
            echo -e "${ERROR} PostgreSQL installation not supported for $PKG_MANAGER"
            return 1
            ;;
    esac
}

configure_postgres_password_auth() {
    print_section "Configuring PostgreSQL Password Auth"

    if ! command -v psql >/dev/null 2>&1; then
        echo -e "${ERROR} psql not found. Install PostgreSQL first."
        return 1
    fi

    find_pg_hba_file() {
        local hba_path=""

        hba_path=$(sudo -u postgres psql -tAc "SHOW hba_file;" 2>>"$LOG_FILE" | tr -d '[:space:]')
        if [ -n "$hba_path" ] && sudo test -f "$hba_path"; then
            echo "$hba_path"
            return 0
        fi

        local data_dir
        data_dir=$(sudo -u postgres psql -tAc "SHOW data_directory;" 2>>"$LOG_FILE" | tr -d '[:space:]')
        if [ -n "$data_dir" ] && sudo test -f "$data_dir/pg_hba.conf"; then
            echo "$data_dir/pg_hba.conf"
            return 0
        fi

        local candidates=(
            "/var/lib/pgsql/data/pg_hba.conf"
            "/var/lib/pgsql/16/data/pg_hba.conf"
            "/var/lib/pgsql/17/data/pg_hba.conf"
            "/var/lib/pgsql/18/data/pg_hba.conf"
            "/var/lib/pgsql/pg_hba.conf"
            "/var/lib/postgresql/data/pg_hba.conf"
            "/var/lib/postgresql/pg_hba.conf"
            "/var/lib/postgres/data/pg_hba.conf"
            "/var/lib/postgres/pg_hba.conf"
        )

        for candidate in "${candidates[@]}"; do
            if sudo test -f "$candidate"; then
                echo "$candidate"
                return 0
            fi
        done

        local pattern
        shopt -s nullglob
        for pattern in /var/lib/pgsql/*/data/pg_hba.conf /var/lib/postgresql/*/data/pg_hba.conf; do
            if sudo test -f "$pattern"; then
                echo "$pattern"
                shopt -u nullglob
                return 0
            fi
        done
        shopt -u nullglob

        return 1
    }

    read -s -p "Enter new password for postgres user: " pg_password
    echo
    read -s -p "Confirm new password: " pg_password_confirm
    echo

    if [ -z "$pg_password" ] || [ "$pg_password" != "$pg_password_confirm" ]; then
        echo -e "${ERROR} Passwords do not match or are empty."
        return 1
    fi

    echo -e "${INFO} Ensuring PostgreSQL service is running..."
    sudo systemctl start postgresql >> "$LOG_FILE" 2>&1 || true

    local hba_file
    if ! hba_file=$(find_pg_hba_file); then
        echo -e "${ERROR} Could not locate pg_hba.conf."
        return 1
    fi

    echo -e "${INFO} Updating postgres user password..."
    sudo -u postgres psql -v ON_ERROR_STOP=1 -c "ALTER USER postgres WITH PASSWORD '$pg_password';" >> "$LOG_FILE" 2>&1

    echo -e "${INFO} Updating authentication method in $hba_file..."
    sudo cp "$hba_file" "$hba_file.bak" >> "$LOG_FILE" 2>&1

    if sudo grep -Eq "^local\s+all\s+all\s+" "$hba_file"; then
        sudo sed -i \
            -e "s/^local\s\+all\s\+all\s\+.*/local all all md5/" \
            -e "s/^host\s\+all\s\+all\s\+127\.0\.0\.1\/32\s\+.*/host all all 127.0.0.1\/32 md5/" \
            -e "s/^host\s\+all\s\+all\s\+::1\/128\s\+.*/host all all ::1\/128 md5/" \
            "$hba_file"
    else
        sudo awk '
            BEGIN {
                inserted=0;
                lines[0]="local all all md5";
                lines[1]="host all all 127.0.0.1/32 md5";
                lines[2]="host all all ::1/128 md5";
            }
            {
                print;
                if (!inserted && $0 ~ /^# TYPE[[:space:]]+DATABASE[[:space:]]+USER/) {
                    for (i=0; i<3; i++) print lines[i];
                    inserted=1;
                }
            }
            END {
                if (!inserted) {
                    for (i=0; i<3; i++) print lines[i];
                }
            }
        ' "$hba_file" | sudo tee "$hba_file.tmp" >/dev/null
        sudo mv "$hba_file.tmp" "$hba_file"
    fi

    echo -e "${INFO} Reloading PostgreSQL configuration..."
    sudo systemctl reload postgresql >> "$LOG_FILE" 2>&1 || sudo systemctl restart postgresql >> "$LOG_FILE" 2>&1

    echo -e "${OK} Password auth configured for postgres user."
}

manage_postgres_roles() {
    print_section "Manage PostgreSQL Roles"

    if ! command -v psql >/dev/null 2>&1; then
        echo -e "${ERROR} psql not found. Install PostgreSQL first."
        return 1
    fi

    local role_name
    read -r -p "Enter role name: " role_name
    if [ -z "$role_name" ]; then
        echo -e "${ERROR} Role name cannot be empty."
        return 1
    fi

    local exists
    exists=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${role_name}';" 2>>"$LOG_FILE" | tr -d '[:space:]')

    local action
    if [ "$exists" = "1" ]; then
        action="alter"
        echo -e "${INFO} Role ${MAGENTA}$role_name${RESET} exists. Updating settings."
    else
        action="create"
        echo -e "${INFO} Role ${MAGENTA}$role_name${RESET} does not exist. Creating."
    fi

    read -s -p "Enter password (leave blank for no change): " role_password
    echo

    local login="NOLOGIN"
    local superuser="NOSUPERUSER"
    local createdb="NOCREATEDB"
    local createrole="NOCREATEROLE"
    local replication="NOREPLICATION"
    local bypassrls="NOBYPASSRLS"

    read -r -p "Allow login? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        login="LOGIN"
    fi

    read -r -p "Superuser? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        superuser="SUPERUSER"
    fi

    read -r -p "Can create databases? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        createdb="CREATEDB"
    fi

    read -r -p "Can create roles? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        createrole="CREATEROLE"
    fi

    read -r -p "Replication role? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        replication="REPLICATION"
    fi

    read -r -p "Bypass row level security? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        bypassrls="BYPASSRLS"
    fi

    local sql
    if [ "$action" = "create" ]; then
        sql="CREATE ROLE \"$role_name\" $login $superuser $createdb $createrole $replication $bypassrls;"
    else
        sql="ALTER ROLE \"$role_name\" $login $superuser $createdb $createrole $replication $bypassrls;"
    fi

    sudo -u postgres psql -v ON_ERROR_STOP=1 -c "$sql" >> "$LOG_FILE" 2>&1

    if [ -n "${role_password:-}" ]; then
        sudo -u postgres psql -v ON_ERROR_STOP=1 -c "ALTER ROLE \"$role_name\" WITH PASSWORD '$role_password';" >> "$LOG_FILE" 2>&1
    fi

    read -r -p "Grant database privileges? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        read -r -p "Database name: " db_name
        if [ -n "$db_name" ]; then
            read -r -p "Privileges (comma-separated, e.g. CONNECT,CREATE,TEMP or ALL): " db_privs
            if [ -n "$db_privs" ]; then
                sudo -u postgres psql -v ON_ERROR_STOP=1 -c "GRANT $db_privs ON DATABASE \"$db_name\" TO \"$role_name\";" >> "$LOG_FILE" 2>&1
                echo -e "${OK} Granted database privileges to ${MAGENTA}$role_name${RESET}."
            fi
        fi
    fi

    echo -e "${OK} Role ${MAGENTA}$role_name${RESET} configured."
}

install_mysql() {
    print_section "Installing MySQL"
    
    case $PKG_MANAGER in
        apt)
            echo -e "${INFO} Installing MySQL Server and related packages..."
            install_package "mysql-server" "$LOG_FILE"
            install_package "libmysqlclient-dev" "$LOG_FILE"
            
            echo -e "${OK} MySQL installed successfully"
            echo -e "${NOTE} MySQL service management:"
            echo -e "  Start:   ${CYAN}sudo systemctl start mysql${RESET}"
            echo -e "  Enable:  ${CYAN}sudo systemctl enable mysql${RESET}"
            echo -e "  Status:  ${CYAN}sudo systemctl status mysql${RESET}"
            echo -e "${NOTE} Secure installation: ${CYAN}sudo mysql_secure_installation${RESET}"
            echo -e "${NOTE} Access MySQL: ${CYAN}sudo mysql${RESET}"
            ;;
        dnf|yum)
            echo -e "${INFO} Installing MySQL Server and related packages..."
            install_package "mysql-server" "$LOG_FILE"
            install_package "mysql-devel" "$LOG_FILE"
            
            echo -e "${OK} MySQL installed successfully"
            echo -e "${NOTE} MySQL service management:"
            echo -e "  Start:   ${CYAN}sudo systemctl start mysqld${RESET}"
            echo -e "  Enable:  ${CYAN}sudo systemctl enable mysqld${RESET}"
            echo -e "  Status:  ${CYAN}sudo systemctl status mysqld${RESET}"
            echo -e "${NOTE} Secure installation: ${CYAN}sudo mysql_secure_installation${RESET}"
            echo -e "${NOTE} Access MySQL: ${CYAN}sudo mysql${RESET}"
            ;;
        pacman)
            echo -e "${INFO} Installing MariaDB (MySQL alternative)..."
            install_package "mariadb" "$LOG_FILE"
            
            # Initialize database
            echo -e "${INFO} Initializing MariaDB database..."
            sudo mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql >> "$LOG_FILE" 2>&1 || true
            
            echo -e "${OK} MariaDB installed successfully"
            echo -e "${NOTE} MariaDB service management:"
            echo -e "  Start:   ${CYAN}sudo systemctl start mariadb${RESET}"
            echo -e "  Enable:  ${CYAN}sudo systemctl enable mariadb${RESET}"
            echo -e "  Status:  ${CYAN}sudo systemctl status mariadb${RESET}"
            echo -e "${NOTE} Secure installation: ${CYAN}sudo mysql_secure_installation${RESET}"
            echo -e "${NOTE} Access MariaDB: ${CYAN}sudo mysql${RESET}"
            ;;
        *)
            echo -e "${ERROR} MySQL installation not supported for $PKG_MANAGER"
            return 1
            ;;
    esac
}

install_nvim() {
    print_section "Installing Neovim"
    
    if command -v nvim &> /dev/null; then
        echo -e "${INFO} Neovim is already installed"
        nvim --version | head -1
        return 0
    fi
    
    # Try to get latest stable version
    case $PKG_MANAGER in
        apt)
            echo -e "${INFO} Adding Neovim PPA for latest version..."
            sudo add-apt-repository -y ppa:neovim-ppa/unstable >> "$LOG_FILE" 2>&1
            update_package_database "$LOG_FILE"
            install_package "neovim" "$LOG_FILE"
            ;;
        *)
            install_package "neovim" "$LOG_FILE"
            ;;
    esac
    
    echo -e "${OK} Neovim installed successfully"
    nvim --version | head -1
}

install_all_tools() {
    print_section "Installing All Developer Tools"
    
    echo -e "${INFO} This will install:"
    echo -e "  - asdf (version manager)"
    echo -e "  - Node.js (via asdf)"
    echo -e "  - Ruby (via asdf)"
    echo -e "  - PostgreSQL (system package)"
    echo -e "  - MySQL (system package)"
    echo -e "  - Neovim (latest)"
    echo ""
    read -p "$(echo -e ${YELLOW}Continue? [y/N]:${RESET} )" -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${INFO} Installation cancelled"
        return 0
    fi
    
    local failed=0
    
    # Install asdf first
    install_asdf || ((failed++))
    
    # Install Node.js and Ruby via asdf
    echo -e "\n${INFO} Installing Node.js (latest via asdf)..."
    install_asdf_plugin "nodejs" && install_tool_version "nodejs" "latest" || ((failed++))
    
    echo -e "\n${INFO} Installing Ruby (latest via asdf)..."
    install_asdf_plugin "ruby" && install_tool_version "ruby" "latest" || ((failed++))
    
    # Install databases via system package manager
    echo -e "\n${INFO} Installing PostgreSQL (system package)..."
    install_postgres || ((failed++))
    
    echo -e "\n${INFO} Installing MySQL (system package)..."
    install_mysql || ((failed++))

    echo -e "\n${INFO} Installing Neovim..."
    install_nvim || ((failed++))
    
    echo -e "\n${CYAN}════════════════════════════════════════${RESET}"
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ All tools installed successfully!${RESET}"
    else
        echo -e "${YELLOW}${BOLD}⚠ $failed installation(s) failed${RESET}"
    fi
    echo -e "${CYAN}════════════════════════════════════════${RESET}\n"
}

# ============================================================================
# MENU FUNCTIONS
# ============================================================================

show_dev_menu() {
    echo -e "${BOLD}Developer Tools:${RESET}\n"
    echo -e "  ${GREEN}1${RESET}) Install asdf (version manager)"
    echo -e "  ${GREEN}2${RESET}) Install Node.js ${CYAN}(via asdf)${RESET}"
    echo -e "  ${GREEN}3${RESET}) Install Ruby ${CYAN}(via asdf)${RESET}"
    echo -e "  ${GREEN}4${RESET}) Install PostgreSQL ${YELLOW}(system package)${RESET}"
    echo -e "  ${GREEN}5${RESET}) Install MySQL ${YELLOW}(system package)${RESET}"
    echo -e "  ${GREEN}6${RESET}) Install Neovim"
    echo -e "  ${GREEN}7${RESET}) Install All Tools"
    echo -e "  ${GREEN}8${RESET}) Configure PostgreSQL Password Auth"
    echo -e "  ${GREEN}9${RESET}) Manage PostgreSQL Roles"
    echo -e "  ${GREEN}10${RESET}) Back to Main Menu"
    echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    show_dev_banner
    
    while true; do
        show_dev_menu
        read -p "$(echo -e ${CYAN}Enter your choice [1-10]:${RESET} )" choice
        
        case $choice in
            1)
                install_asdf
                read -p "Press Enter to continue..."
                show_dev_banner
                ;;
            2)
                install_nodejs
                read -p "Press Enter to continue..."
                show_dev_banner
                ;;
            3)
                install_ruby
                read -p "Press Enter to continue..."
                show_dev_banner
                ;;
            4)
                install_postgres
                read -p "Press Enter to continue..."
                show_dev_banner
                ;;
            5)
                install_mysql
                read -p "Press Enter to continue..."
                show_dev_banner
                ;;
            6)
                install_nvim
                read -p "Press Enter to continue..."
                show_dev_banner
                ;;
            7)
                install_all_tools
                read -p "Press Enter to continue..."
                show_dev_banner
                ;;
            8)
                configure_postgres_password_auth
                read -p "Press Enter to continue..."
                show_dev_banner
                ;;
            9)
                manage_postgres_roles
                read -p "Press Enter to continue..."
                show_dev_banner
                ;;
            10)
                echo -e "\n${CYAN}Returning to main menu...${RESET}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${RESET}\n"
                sleep 1
                show_dev_banner
                ;;
        esac
    done
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi

