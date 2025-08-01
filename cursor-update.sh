#!/bin/bash
#
# Cursor Update - UNOFFICIAL Installer & Version Manager
# Unofficial Linux installer and version manager for Cursor IDE
# 
# Copyright (c) 2025 jwillians
# Licensed under MIT License - see LICENSE file for details
#
# ⚠️  DISCLAIMER: This is an UNOFFICIAL installer created by a fan.
#    NOT affiliated with, endorsed by, or officially supported by
#    Anysphere (the creators of Cursor IDE). Use at your own risk.
#    Cursor IDE is a trademark of Anysphere.
#
# Install with: curl -fsSL https://raw.githubusercontent.com/jwillians/cursor-update/main/cursor-update.sh | bash
# Or download and run: bash cursor-update.sh
#
# Repository: https://github.com/jwillians/cursor-update
# This script is completely standalone and requires no additional files.
#

# Exit on error, but allow some commands to fail gracefully  
set -e

# Debug function
debug_log() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo "DEBUG: $*" >&2
    fi
}

# Version and metadata
INSTALLER_VERSION="1.1.1"
SCRIPT_NAME="Cursor Update"
SCRIPT_URL="https://raw.githubusercontent.com/jwillians/cursor-update/main/cursor-update.sh"
SYSTEM_SCRIPT_PATH="/usr/local/bin/cursor-update"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo
    echo -e "${BOLD}${CYAN}================================================================${NC}"
    echo -e "${BOLD}${CYAN}    🎯 ${SCRIPT_NAME} v${INSTALLER_VERSION}${NC}"
    echo -e "${BOLD}${CYAN}    Unofficial Linux Installer & Version Manager for Cursor IDE${NC}"
    echo -e "${BOLD}${CYAN}================================================================${NC}"
    
    # Show current Cursor version if available
    local current_cursor=$(get_current_cursor_version)
    if [[ -n "$current_cursor" ]]; then
        echo -e "${BOLD}${GREEN}    📍 Current Cursor Version: v${current_cursor}${NC}"
    else
        echo -e "${BOLD}${YELLOW}    📍 No Cursor installation detected${NC}"
    fi
    echo -e "${BOLD}${CYAN}================================================================${NC}"
    echo
    echo -e "${BOLD}${YELLOW}⚠️  DISCLAIMER: This is an UNOFFICIAL installer created by a fan${NC}"
    echo -e "${BOLD}${YELLOW}   NOT affiliated with Anysphere (Cursor IDE creators)${NC}"
    echo -e "${BOLD}${YELLOW}   Use at your own risk. Cursor IDE is a trademark of Anysphere.${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_step() {
    echo -e "${PURPLE}▶${NC} ${BOLD}$1${NC}"
}

# Utility functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get currently installed Cursor version
get_current_cursor_version() {
    local current_version=""
    
    # Try different methods to get version
    if [[ -f "/opt/cursor.appimage" ]]; then
        # Try to get version from the AppImage
        current_version=$(timeout 5 /opt/cursor.appimage --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi
    
    # Fallback: check active symlink if managed by this script
    if [[ -z "$current_version" ]]; then
        local cursor_dir="$HOME/.local/share/cursor-installer"
        local active_symlink="$cursor_dir/active"
        
        if [[ -L "$active_symlink" ]]; then
            local target_path=$(readlink "$active_symlink")
            current_version=$(echo "$target_path" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        fi
    fi
    
    # Fallback: check for cursor command
    if [[ -z "$current_version" ]] && command_exists cursor; then
        current_version=$(timeout 5 cursor --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi
    
    echo "$current_version"
}

# Check if script needs self-update
check_script_update() {
    print_step "Checking for script updates..."
    
    local remote_version=""
    local current_script_version="$INSTALLER_VERSION"
    
    # Get remote version
    if command_exists curl; then
        remote_version=$(curl -fsSL "$SCRIPT_URL" 2>/dev/null | grep '^INSTALLER_VERSION=' | head -1 | cut -d'"' -f2)
    elif command_exists wget; then
        remote_version=$(wget -qO- "$SCRIPT_URL" 2>/dev/null | grep '^INSTALLER_VERSION=' | head -1 | cut -d'"' -f2)
    fi
    
    if [[ -n "$remote_version" && "$remote_version" != "$current_script_version" ]]; then
        print_warning "Script update available: v$current_script_version → v$remote_version"
        if ask_permission "Update the script to the latest version?"; then
            update_script
            return 0
        fi
    else
        print_success "Script is up to date (v$current_script_version)"
    fi
    
    return 1
}

# Update the script itself
update_script() {
    print_step "Updating script to latest version..."
    
    local temp_script="/tmp/cursor-update-new.sh"
    
    # Download latest version
    if command_exists curl; then
        curl -fsSL "$SCRIPT_URL" -o "$temp_script"
    elif command_exists wget; then
        wget -qO "$temp_script" "$SCRIPT_URL"
    else
        print_error "Neither curl nor wget available for script update"
        return 1
    fi
    
    if [[ ! -f "$temp_script" ]]; then
        print_error "Failed to download script update"
        return 1
    fi
    
    # Make executable
    chmod +x "$temp_script"
    
    # If running from system location, update it
    if [[ -f "$SYSTEM_SCRIPT_PATH" ]]; then
        print_info "Updating system script..."
        sudo cp "$temp_script" "$SYSTEM_SCRIPT_PATH"
        sudo chmod +x "$SYSTEM_SCRIPT_PATH"
        print_success "System script updated successfully"
        
        # Clean up and restart with system script
        rm -f "$temp_script"
        print_info "Restarting with updated script..."
        exec "$SYSTEM_SCRIPT_PATH" "$@"
    else
        # Replace current script if possible
        local current_script_path="$0"
        if [[ -w "$current_script_path" ]]; then
            cp "$temp_script" "$current_script_path"
            chmod +x "$current_script_path"
            rm -f "$temp_script"
            print_success "Script updated successfully"
            print_info "Restarting with updated script..."
            exec "$current_script_path" "$@"
        else
            print_warning "Cannot update current script (no write permission)"
            print_info "Please re-run the updated script manually:"
            print_info "bash $temp_script"
            exit 0
        fi
    fi
}

# Install script to system
install_script_to_system() {
    if [[ -f "$SYSTEM_SCRIPT_PATH" ]]; then
        print_info "Script already installed at $SYSTEM_SCRIPT_PATH"
        return 0
    fi
    
    print_step "Installing script to system..."
    
    if ask_permission "Install cursor-update command system-wide?"; then
        local current_script="$0"
        
        # If we're running from a temp location (curl pipe), download the script properly
        if [[ "$current_script" == "/dev/fd/"* ]] || [[ "$current_script" == "/proc/self/fd/"* ]]; then
            print_info "Downloading script for system installation..."
            local temp_script="/tmp/cursor-update.sh"
            
            if command_exists curl; then
                curl -fsSL "$SCRIPT_URL" -o "$temp_script"
            elif command_exists wget; then
                wget -qO "$temp_script" "$SCRIPT_URL"
            else
                print_error "Cannot download script for system installation"
                return 1
            fi
            
            current_script="$temp_script"
            chmod +x "$current_script"
        fi
        
        # Copy to system location
        sudo cp "$current_script" "$SYSTEM_SCRIPT_PATH"
        sudo chmod +x "$SYSTEM_SCRIPT_PATH"
        
        # Clean up temp file if we created one
        if [[ "$current_script" == "/tmp/cursor-update.sh" ]]; then
            rm -f "$current_script"
        fi
        
        print_success "Script installed successfully!"
        print_info "You can now run: cursor-update"
        
        return 0
    fi
    
    return 1
}

# Check for Cursor updates and offer auto-update
check_cursor_update() {
    local current_version="$1"
    
    if [[ -z "$current_version" ]]; then
        print_info "No current Cursor installation detected"
        return 1
    fi
    
    print_step "Checking for Cursor updates..."
    print_info "Current Cursor version: v$current_version"
    
    # Create Python installer to check latest version
    local temp_script="/tmp/cursor_version_check_$$.py"
    create_python_installer > /dev/null
    local python_installer=$(create_python_installer)
    
    # Get latest available version
    local latest_version=""
    if [[ -f "$python_installer" ]]; then
        print_info "🔍 Fetching latest Cursor version from API..."
        # Add debug output to understand what's happening
        local version_output=$(timeout 30 python3 "$python_installer" list 2>&1 | head -10)
        debug_log "Version check output: $version_output"
        
        latest_version=$(echo "$version_output" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/v//')
        debug_log "Extracted latest version: $latest_version"
        rm -f "$python_installer"
    fi
    
    # If no version found, try multiple API fallbacks
    if [[ -z "$latest_version" ]]; then
        print_info "🔄 Trying direct API fallbacks..."
        
        # Try official Cursor API
        latest_version=$(curl -s "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable" 2>/dev/null | grep -o '"version":"[^"]*"' | sed 's/"version":"\([^"]*\)"/\1/')
        debug_log "Official API version: $latest_version"
        
        # If still no version, try GitHub releases API
        if [[ -z "$latest_version" ]]; then
            print_info "🔄 Trying GitHub releases API..."
            latest_version=$(curl -s "https://api.github.com/repos/getcursor/cursor/releases/latest" 2>/dev/null | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/' | sed 's/v//')
            debug_log "GitHub API version: $latest_version"
        fi
        
        # Try alternative version check by probing download URLs
        if [[ -z "$latest_version" ]]; then
            print_info "🔄 Probing for latest versions..."
            # Test multiple version ranges to find latest
            local found_version=""
            
            # Test 1.4.x versions first (newest)
            for patch in {0..10}; do
                local test_version="1.4.$patch"
                local test_url="https://downloads.cursor.com/production/a1fa6fc7d2c2f520293aad84aaa38d091dee6fef/linux/x64/Cursor-${test_version}-x86_64.AppImage"
                if curl -s --head "$test_url" 2>/dev/null | grep -q "200 OK"; then
                    found_version="$test_version"
                    debug_log "Found version by probing: $test_version"
                fi
            done
            
            # If no 1.4.x found, test 1.3.x versions
            if [[ -z "$found_version" ]]; then
                for patch in {9..20}; do
                    local test_version="1.3.$patch"
                    local test_url="https://downloads.cursor.com/production/a1fa6fc7d2c2f520293aad84aaa38d091dee6fef/linux/x64/Cursor-${test_version}-x86_64.AppImage"
                    if curl -s --head "$test_url" 2>/dev/null | grep -q "200 OK"; then
                        found_version="$test_version"
                        debug_log "Found version by probing: $test_version"
                    fi
                done
            fi
            
            latest_version="$found_version"
        fi
    fi
    
    if [[ -n "$latest_version" && "$latest_version" != "$current_version" ]]; then
        print_warning "Cursor update available: v$current_version → v$latest_version"
        
        # Check if Cursor is currently running
        local cursor_running=false
        local cursor_processes=$(ps aux | grep -E '(/cursor\.appimage|/Cursor.*\.AppImage|cursor --no-sandbox)' | grep -v grep | grep -v "install-cursor.sh" | wc -l)
        
        if [[ "$cursor_processes" -gt 0 ]]; then
            cursor_running=true
            print_info "Cursor is currently running"
        fi
        
        if ask_permission "Update Cursor to v$latest_version now?"; then
            # If Cursor is running, offer to close and reopen
            local should_reopen=false
            if [[ "$cursor_running" == true ]]; then
                if ask_permission "Close Cursor, update, and reopen automatically?"; then
                    should_reopen=true
                    print_info "Closing Cursor..."
                    
                    # Close Cursor gracefully
                    local cursor_pids=$(ps aux | grep -E '(/cursor\.appimage|/Cursor.*\.AppImage|cursor --no-sandbox)' | grep -v grep | grep -v "install-cursor.sh" | awk '{print $2}')
                    for pid in $cursor_pids; do
                        if [[ -n "$pid" ]]; then
                            kill -TERM "$pid" 2>/dev/null || true
                        fi
                    done
                    
                    sleep 3
                    
                    # Force kill if still running
                    cursor_pids=$(ps aux | grep -E '(/cursor\.appimage|/Cursor.*\.AppImage|cursor --no-sandbox)' | grep -v grep | grep -v "install-cursor.sh" | awk '{print $2}')
                    for pid in $cursor_pids; do
                        if [[ -n "$pid" ]]; then
                            kill -KILL "$pid" 2>/dev/null || true
                        fi
                    done
                    
                    print_success "Cursor closed successfully"
                fi
            fi
            
            # Perform the update
            print_step "Updating Cursor to v$latest_version..."
            local python_installer=$(create_python_installer)
            
            if python3 "$python_installer" install "$latest_version"; then
                rm -f "$python_installer"
                print_success "Cursor updated successfully to v$latest_version!"
                
                # Reopen Cursor if requested
                if [[ "$should_reopen" == true ]]; then
                    print_info "Reopening Cursor..."
                    sleep 2
                    
                    # Try different ways to launch Cursor
                    if command_exists cursor; then
                        nohup cursor > /dev/null 2>&1 &
                    elif [[ -f "/opt/cursor.appimage" ]]; then
                        nohup /opt/cursor.appimage > /dev/null 2>&1 &
                    fi
                    
                    print_success "Cursor reopened successfully!"
                fi
                
                return 0
            else
                rm -f "$python_installer"
                print_error "Failed to update Cursor"
                return 1
            fi
        fi
    else
        if [[ -n "$latest_version" ]]; then
            print_success "Cursor is up to date (v$current_version)"
        else
            print_warning "Could not check for Cursor updates (network issue?)"
        fi
    fi
    
    return 1
}

ask_permission() {
    local question="$1"
    local default="${2:-y}"
    
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    echo -e "${YELLOW}❓${NC} ${question} ${prompt}"
    read -r response
    
    if [[ -z "$response" ]]; then
        response="$default"
    fi
    
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# System detection
detect_system() {
    print_step "Detecting system information..."
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists lsb_release; then
            OS_ID=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
            OS_VERSION=$(lsb_release -sr)
        elif [[ -f /etc/os-release ]]; then
            . /etc/os-release
            OS_ID=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
            OS_VERSION="$VERSION_ID"
        else
            OS_ID="linux"
            OS_VERSION="unknown"
        fi
    else
        print_error "This installer only supports Linux systems"
        exit 1
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) CURSOR_ARCH="x64" ;;
        aarch64|arm64) CURSOR_ARCH="arm64" ;;
        *) 
            print_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    print_info "System: ${OS_ID} ${OS_VERSION}"
    print_info "Architecture: ${ARCH} (${CURSOR_ARCH})"
    
    # Check if Ubuntu/Debian
    if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" ]]; then
        print_warning "This installer is designed for Linux systems (tested on Ubuntu/Debian)"
        if ! ask_permission "Continue anyway?"; then
            print_info "Installation cancelled"
            exit 0
        fi
    fi
}

# Check dependencies
check_dependencies() {
    print_step "Checking system dependencies..."
    
    local missing_deps=()
    local required_system_deps=("curl" "wget" "sudo")
    
    # Check system dependencies
    for dep in "${required_system_deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_warning "Missing system dependencies: ${missing_deps[*]}"
        if ask_permission "Install missing system dependencies?"; then
            print_info "Installing system dependencies..."
            sudo apt update
            sudo apt install -y "${missing_deps[@]}"
            print_success "System dependencies installed"
        else
            print_error "Required dependencies are missing. Cannot continue."
            exit 1
        fi
    else
        print_success "All system dependencies found"
    fi
    
    # Check Python
    if command_exists python3; then
        PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        print_success "Python ${PYTHON_VERSION} found"
        
        # Check if version is adequate (3.8+)
        if python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"; then
            print_success "Python version is adequate"
        else
            print_error "Python 3.8+ is required. Found: ${PYTHON_VERSION}"
            exit 1
        fi
    else
        print_warning "Python 3 not found"
        if ask_permission "Install Python 3?"; then
            print_info "Installing Python 3..."
            sudo apt update
            sudo apt install -y python3 python3-pip
            print_success "Python 3 installed"
        else
            print_error "Python 3 is required. Cannot continue."
            exit 1
        fi
    fi
    
    # Check pip
    if ! command_exists pip3; then
        print_warning "pip3 not found"
        if ask_permission "Install pip3?"; then
            print_info "Installing pip3..."
            sudo apt update
            sudo apt install -y python3-pip
            print_success "pip3 installed"
        else
            print_error "pip3 is required. Cannot continue."
            exit 1
        fi
    fi
    
    # Install Python dependencies
    print_info "Installing Python dependencies..."
    local python_deps=("requests" "beautifulsoup4" "lxml" "packaging")
    local missing_deps=()
    
    # Check which dependencies are missing
    for dep in "${python_deps[@]}"; do
        local import_name="$dep"
        # Map package names to import names
        case "$dep" in
            "beautifulsoup4") import_name="bs4" ;;
        esac
        
        if ! python3 -c "import $import_name" 2>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_info "Missing Python packages: ${missing_deps[*]}"
        
        # Try different installation methods based on system
        if command_exists apt && [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
            print_info "Using system package manager for Python dependencies..."
            local apt_packages=()
            for dep in "${missing_deps[@]}"; do
                case "$dep" in
                    "requests") apt_packages+=("python3-requests") ;;
                    "beautifulsoup4") apt_packages+=("python3-bs4") ;;
                    "lxml") apt_packages+=("python3-lxml") ;;
                    "packaging") apt_packages+=("python3-packaging") ;;
                esac
            done
            
            if [[ ${#apt_packages[@]} -gt 0 ]]; then
                if ask_permission "Install Python packages via apt: ${apt_packages[*]}?"; then
                    sudo apt update
                    sudo apt install -y "${apt_packages[@]}"
                fi
            fi
        else
            # Fallback: try pip with different methods
            for dep in "${missing_deps[@]}"; do
                print_info "Installing Python package: $dep"
                if pip3 install --user "$dep" 2>/dev/null; then
                    print_success "Installed $dep with --user"
                elif pip3 install --user "$dep" --break-system-packages 2>/dev/null; then
                    print_success "Installed $dep with --break-system-packages"
                else
                    print_warning "Could not install $dep automatically"
                    if ask_permission "Try installing $dep with sudo?"; then
                        sudo pip3 install "$dep" || {
                            print_warning "Failed to install $dep"
                        }
                    fi
                fi
            done
        fi
        
        # Verify installation (with correct import names)
        local still_missing=()
        for dep in "${missing_deps[@]}"; do
            local import_name="$dep"
            # Map package names to import names
            case "$dep" in
                "beautifulsoup4") import_name="bs4" ;;
            esac
            
            if ! python3 -c "import $import_name" 2>/dev/null; then
                still_missing+=("$dep")
            fi
        done
        
        if [[ ${#still_missing[@]} -gt 0 ]]; then
            print_warning "Some Python packages are still missing: ${still_missing[*]}"
            print_info "The installer will continue, but some features may not work"
            if ! ask_permission "Continue anyway?"; then
                print_info "Installation cancelled"
                exit 0
            fi
        fi
    fi
    
    print_success "All Python dependencies ready"
}

# Check if a desktop file follows our standard pattern
is_our_desktop_file() {
    local desktop_file="$1"
    
    if [[ ! -f "$desktop_file" ]]; then
        return 1
    fi
    
    # Check for our signature patterns
    local our_patterns=(
        "Comment=The AI-first code editor. Edit code with AI superpowers."
        "StartupWMClass=cursor"
        "Keywords=cursor;code;editor;ide;development;programming;ai;copilot"
        "--no-sandbox %F"
    )
    
    # All patterns must be present for it to be our file
    for pattern in "${our_patterns[@]}"; do
        if ! grep -q -F "$pattern" "$desktop_file" 2>/dev/null; then
            return 1
        fi
    done
    
    return 0
}

# Clean up old desktop entries function
cleanup_old_desktop_entries() {
    print_info "Cleaning up old desktop entries and shell commands..."
    
    # Find and remove all cursor-related desktop files
    local cursor_desktops=()
    if [[ -d "/usr/share/applications" ]]; then
        while IFS= read -r -d '' desktop_file; do
            if [[ -n "$desktop_file" ]]; then
                cursor_desktops+=("$desktop_file")
            fi
        done < <(find /usr/share/applications -maxdepth 1 -iname "*cursor*.desktop" -type f -print0 2>/dev/null)
    fi
    
    # Also check user-specific applications directory
    if [[ -d "$HOME/.local/share/applications" ]]; then
        while IFS= read -r -d '' desktop_file; do
            if [[ -n "$desktop_file" ]]; then
                cursor_desktops+=("$desktop_file")
            fi
        done < <(find "$HOME/.local/share/applications" -maxdepth 1 -iname "*cursor*.desktop" -type f -print0 2>/dev/null)
    fi
    
    # Analyze found desktop files (remove only non-standard ones)
    if [[ ${#cursor_desktops[@]} -gt 0 ]]; then
        print_info "Found ${#cursor_desktops[@]} desktop entries to analyze:"
        local removed_count=0
        local updated_count=0
        for desktop_file in "${cursor_desktops[@]}"; do
            if [[ -f "$desktop_file" ]]; then
                # Check if desktop file follows our standard pattern
                if is_our_desktop_file "$desktop_file"; then
                    print_info "  • Found our standard file: $desktop_file - will update it"
                    ((updated_count++))
                    # Don't remove it, will be updated when we create the new one
                else
                    print_info "  • Removing non-standard entry: $desktop_file"
                    if [[ "$desktop_file" == /usr/share/applications/* ]]; then
                        sudo rm -f "$desktop_file" 2>/dev/null || print_warning "Failed to remove $desktop_file"
                    else
                        rm -f "$desktop_file" 2>/dev/null || print_warning "Failed to remove $desktop_file"
                    fi
                    ((removed_count++))
                fi
            fi
        done
        if [[ $removed_count -eq 0 && $updated_count -eq 0 ]]; then
            print_info "No desktop entries processed"
        elif [[ $removed_count -eq 0 ]]; then
            print_info "Found $updated_count standard entries to update"
        elif [[ $updated_count -eq 0 ]]; then
            print_info "Removed $removed_count non-standard entries"
        else
            print_info "Removed $removed_count non-standard entries, will update $updated_count standard entries"
        fi
    else
        print_info "No desktop entries found"
    fi
    
    # Remove old shell commands
    local shell_commands=("/usr/local/bin/cursor" "/usr/bin/cursor")
    for cmd in "${shell_commands[@]}"; do
        if [[ -f "$cmd" ]]; then
            print_info "Removing old shell command: $cmd"
            sudo rm -f "$cmd" 2>/dev/null || print_warning "Failed to remove $cmd"
        fi
    done
    
    # Remove old icons (but protect ones referenced by our standard desktop files)
    local old_icons=("/usr/share/pixmaps/cursor.png" "/usr/share/icons/hicolor/*/apps/cursor.png")
    local icon_in_use=false
    
    # Check if any of our standard desktop files reference cursor icons
    for desktop_file in "${cursor_desktops[@]}"; do
        if [[ -f "$desktop_file" ]] && is_our_desktop_file "$desktop_file"; then
            if grep -q "Icon=/usr/share/pixmaps/cursor.png\|Icon=cursor" "$desktop_file" 2>/dev/null; then
                icon_in_use=true
                break
            fi
        fi
    done
    
    for icon_pattern in "${old_icons[@]}"; do
        for icon_file in $icon_pattern; do
            if [[ -f "$icon_file" ]]; then
                if [[ "$icon_in_use" == true ]]; then
                    print_info "Preserving icon (in use by standard desktop file): $icon_file"
                else
                    print_info "Removing unused icon: $icon_file"
                    sudo rm -f "$icon_file" 2>/dev/null || print_warning "Failed to remove $icon_file"
                fi
            fi
        done
    done
    
    # Update desktop database to ensure changes take effect
    print_info "Updating desktop database..."
    sudo update-desktop-database /usr/share/applications/ 2>/dev/null || true
    if [[ -d "$HOME/.local/share/applications" ]]; then
        update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    fi
    
    # Force desktop environment refresh
    xdg-desktop-menu forceupdate 2>/dev/null || true
    
    print_success "Old desktop entries cleanup completed"
}

# Check for existing Cursor installations
check_existing_installations() {
    print_step "Checking for existing Cursor installations..."
    
    local existing_installations=()
    local running_processes=()
    
    # Check for running Cursor processes (more specific detection)
    # Look for actual Cursor IDE processes, not just any process with "cursor" in name
    # Exclude debug version ./Cursor-1.3.6-x86_64.AppImage --no-sandbox
    local cursor_processes=$(ps aux | grep -E '(/cursor\.appimage|/Cursor.*\.AppImage|cursor --no-sandbox)' | grep -v grep | grep -v "install-cursor.sh" | grep -v "Cursor-1.3.6-x86_64.AppImage --no-sandbox")
    local cursor_check=$(echo "$cursor_processes" | wc -l)
    if [[ "$cursor_check" -gt 0 && -n "$(echo "$cursor_processes" | tr -d '[:space:]')" ]]; then
        local cursor_pids=$(echo "$cursor_processes" | awk '{print $2}' | tr '\n' ' ')
        running_processes+=("Running Cursor IDE processes found (PIDs: $cursor_pids)")
        print_info "🐛 DEBUG: Excluding debug version ./Cursor-1.3.6-x86_64.AppImage --no-sandbox from process detection"
    fi
    
    # Check common installation locations
    local common_locations=(
        "/opt/cursor.appimage"
        "/usr/local/bin/cursor"
        "/snap/bin/cursor"
        "/usr/bin/cursor"
        "$HOME/bin/cursor"
        "$HOME/.local/bin/cursor"
        "$HOME/Applications/cursor"
        "$HOME/Downloads/cursor"*
        "$HOME/Downloads/Cursor"*
    )
    
    for location in "${common_locations[@]}"; do
        if [[ -e $location ]]; then
            existing_installations+=("$location")
        fi
    done
    
    # Check for AppImages in common download locations
    local appimage_locations=(
        "$HOME/Downloads"
        "$HOME/Desktop"
        "$HOME/Applications"
        "$HOME/bin"
        "$HOME/.local/bin"
        "/tmp"
        "/opt"
    )
    
    for dir in "${appimage_locations[@]}"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' file; do
                if [[ $(basename "$file") =~ [Cc]ursor.*\.AppImage$ ]]; then
                    # Get version info if possible
                    local version_info=""
                    if [[ -x "$file" ]]; then
                        version_info=$(timeout 3 "$file" --version 2>/dev/null | head -1 || echo "")
                        if [[ -n "$version_info" ]]; then
                            existing_installations+=("$file (Version: $version_info)")
                        else
                            existing_installations+=("$file")
                        fi
                    else
                        existing_installations+=("$file")
                    fi
                fi
            done < <(find "$dir" -maxdepth 2 -name "*[Cc]ursor*.AppImage" -type f -print0 2>/dev/null)
        fi
    done
    
    # Check for currently running Cursor installation path
    if [[ ${#running_processes[@]} -gt 0 ]]; then
        local running_paths=$(echo "$cursor_processes" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}' | grep -o '/[^[:space:]]*\.appimage\|/[^[:space:]]*cursor\.exe\|/[^[:space:]]*/cursor$' | sort -u)
        while IFS= read -r path; do
            if [[ -n "$path" && -f "$path" && ! "$path" =~ /tmp/\.mount_cursor.*|.*\.sh$|.*crashpad.*|.*chrome.*|.*resources.* ]]; then
                existing_installations+=("$path (Currently running)")
            fi
        done <<< "$running_paths"
    fi
    
    # Check for Snap installations
    if command_exists snap && snap list cursor &>/dev/null; then
        existing_installations+=("Snap package: cursor")
    fi
    
    # Check for system package installations
    if command_exists dpkg && dpkg -s cursor &>/dev/null; then
        existing_installations+=("System package (apt): cursor")
    fi
    
    # Remove duplicates and our own managed installation, prioritizing "(Currently running)" status
    local unique_installations=()
    for installation in "${existing_installations[@]}"; do
        # Skip our own managed installations, system temp files, and DEBUG VERSION
        if [[ "$installation" != *"cursor-installer/versions"* ]] && [[ "$installation" != "/opt/cursor.appimage" ]] && [[ "$installation" != *"/tmp/.mount_cursor"* ]] && [[ "$installation" != *"Cursor-1.3.6-x86_64.AppImage"* ]]; then
            # Extract base path without status info
            local base_path=$(echo "$installation" | sed 's/ (Currently running)//' | sed 's/ (Version:.*//')
            
            # Check if base path already exists in unique list
            local found_index=-1
            for i in "${!unique_installations[@]}"; do
                local existing_base=$(echo "${unique_installations[$i]}" | sed 's/ (Currently running)//' | sed 's/ (Version:.*//')
                if [[ "$existing_base" == "$base_path" ]]; then
                    found_index=$i
                    break
                fi
            done
            
            if [[ $found_index -eq -1 ]]; then
                # Not found, add it
                unique_installations+=("$installation")
            elif [[ "$installation" == *"(Currently running)"* ]]; then
                # Found but this one has "Currently running" status, replace
                unique_installations[$found_index]="$installation"
            fi
        elif [[ "$installation" == *"Cursor-1.3.6-x86_64.AppImage"* ]]; then
            print_info "🐛 DEBUG: Protecting debug version from removal: $installation"
        fi
    done
    
    # Report findings
    if [[ ${#running_processes[@]} -gt 0 ]]; then
        print_warning "Cursor is currently running!"
        for process in "${running_processes[@]}"; do
            print_info "  • $process"
        done
        echo
        
        # Check if debug version is running
        local has_debug_version=$(ps aux | grep -E "Cursor-1.3.6-x86_64.AppImage --no-sandbox" | grep -v grep | wc -l)
        if [[ "$has_debug_version" -gt 0 ]]; then
            print_warning "Debug version detected - skipping process termination to protect your work"
            print_info "Installation will continue with Cursor running"
        elif ask_permission "Stop all Cursor processes before installation?" "n"; then
            print_info "Stopping Cursor processes..."
            
            # Get specific cursor PIDs using the same detection as above
            local cursor_pids=($(echo "$cursor_processes" | awk '{print $2}' | tr '\n' ' '))
            
            if [[ ${#cursor_pids[@]} -gt 0 ]]; then
                print_info "Found ${#cursor_pids[@]} Cursor processes to stop..."
                
                # Stop processes individually with TERM signal
                for pid in "${cursor_pids[@]}"; do
                    if [[ -n "$pid" && "$pid" != "$$" ]]; then
                        debug_log "Stopping process $pid"
                        kill -TERM "$pid" 2>/dev/null || true
                    fi
                done
                
                sleep 3
                
                # Check which processes are still running and force kill (exclude debug version)
                local remaining_cursor_processes=$(ps aux | grep -E '(/cursor\.appimage|/Cursor.*\.AppImage|cursor --no-sandbox)' | grep -v grep | grep -v "install-cursor.sh" | grep -v "Cursor-1.3.6-x86_64.AppImage --no-sandbox")
                local remaining_pids=($(echo "$remaining_cursor_processes" | awk '{print $2}' | tr '\n' ' '))
                if [[ ${#remaining_pids[@]} -gt 0 ]]; then
                    print_info "Force stopping ${#remaining_pids[@]} remaining processes..."
                    for pid in "${remaining_pids[@]}"; do
                        if [[ -n "$pid" && "$pid" != "$$" ]]; then
                            debug_log "Force killing process $pid"
                            kill -KILL "$pid" 2>/dev/null || true
                        fi
                    done
                    sleep 1
                fi
                
                # Final verification (exclude debug version)
                local final_cursor_processes=$(ps aux | grep -E '(/cursor\.appimage|/Cursor.*\.AppImage|cursor --no-sandbox)' | grep -v grep | grep -v "install-cursor.sh" | grep -v "Cursor-1.3.6-x86_64.AppImage --no-sandbox")
                local final_check=($(echo "$final_cursor_processes" | awk '{print $2}' | tr '\n' ' '))
                if [[ ${#final_check[@]} -gt 0 ]]; then
                    print_warning "Some Cursor processes may still be running (${#final_check[@]} processes)"
                else
                    print_success "All Cursor processes stopped successfully"
                fi
            else
                print_success "No Cursor processes found to stop"
            fi
        else
            print_warning "Installation will continue with Cursor running"
            print_info "Note: Some features may not work properly until Cursor is restarted"
        fi
        echo
        
        # Ensure script continues regardless of process stopping result
        debug_log "Process stopping section completed"
    fi
    
    if [[ ${#unique_installations[@]} -gt 0 ]]; then
        print_warning "Found existing Cursor installations:"
        for installation in "${unique_installations[@]}"; do
            print_info "  • $installation"
        done
        echo
        
        if ask_permission "Remove existing installations to avoid conflicts?"; then
            print_info "Removing existing installations..."
            
            for installation in "${unique_installations[@]}"; do
                if [[ "$installation" == "Snap package:"* ]]; then
                    print_info "Removing Snap package..."
                    sudo snap remove cursor 2>/dev/null || print_warning "Failed to remove Snap package"
                elif [[ "$installation" == "System package"* ]]; then
                    print_info "Removing system package..."
                    sudo apt remove -y cursor 2>/dev/null || print_warning "Failed to remove system package"
                elif [[ -f "$installation" ]]; then
                    print_info "Removing: $installation"
                    if ! rm -f "$installation" 2>/dev/null; then
                        print_info "Using sudo to remove $installation..."
                        sudo rm -f "$installation" || print_warning "Failed to remove with sudo"
                    fi
                elif [[ -d "$installation" ]]; then
                    print_info "Removing directory: $installation"
                    if ! rm -rf "$installation" 2>/dev/null; then
                        print_info "Using sudo to remove $installation..."
                        sudo rm -rf "$installation" || print_warning "Failed to remove with sudo"
                    fi
                fi
            done
            
            # Clean up desktop entries and shell commands
            print_info "Cleaning up desktop entries and shell commands..."
            cleanup_old_desktop_entries
            
            print_success "Existing installations cleaned up"
        else
            print_warning "Existing installations will remain"
            print_info "This may cause conflicts or confusion about which version is active"
            echo
            # Even if keeping installations, we should clean up old desktop entries to avoid conflicts
            print_info "Cleaning up old desktop entries to avoid conflicts with new installation..."
            cleanup_old_desktop_entries
        fi
        echo
    else
        print_success "No conflicting installations found"
    fi
    
    print_info "Existing installations check completed"
    debug_log "check_existing_installations function completed successfully"
    
    # Make sure we can continue even if process stopping had issues
    return 0
}

# Check libfuse2 for AppImage
check_libfuse2() {
    print_step "Checking AppImage compatibility..."
    
    if ! ldconfig -p | grep -q libfuse.so.2; then
        print_warning "libfuse2 not found (required for AppImage execution)"
        
        # Check Ubuntu version for special handling
        if [[ "$OS_ID" == "ubuntu" ]] && [[ "${OS_VERSION%%.*}" -ge 24 ]]; then
            print_warning "Ubuntu 24.04+ detected - libfuse2 may not be available in default repos"
            print_info "AppImage extraction will be used as fallback"
        fi
        
        if ask_permission "Install libfuse2 for AppImage support?"; then
            print_info "Installing libfuse2..."
            sudo apt update
            sudo apt install -y libfuse2 || {
                print_warning "Failed to install libfuse2 from default repos"
                print_info "AppImage extraction will be used instead"
            }
        else
            print_info "Skipping libfuse2 installation - AppImage extraction will be used"
        fi
    else
        print_success "libfuse2 found - AppImage support ready"
    fi
    
    debug_log "check_libfuse2 function completed successfully"
}

# Create Python installer script
create_python_installer() {
    local temp_script="/tmp/cursor_installer_$$.py"
    
    cat > "$temp_script" << 'PYTHON_SCRIPT_EOF'
#!/usr/bin/env python3

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional
from urllib.parse import urljoin, urlparse

import requests
from packaging import version

class Colors:
    """Terminal color codes for better UX."""
    GREEN = '\033[0;32m'
    ORANGE = '\033[0;33m'
    RED = '\033[0;31m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color
    BOLD = '\033[1m'

class CursorInstaller:
    """Advanced Cursor IDE installer with version management capabilities."""
    
    # GitHub API Configuration
    GITHUB_RELEASES_URL = "https://raw.githubusercontent.com/oslook/cursor-ai-downloads/main/version-history.json"
    
    # System Paths
    SYSTEM_INSTALL_PATH = Path("/opt/cursor.appimage")
    DESKTOP_FILE_PATH = Path("/usr/share/applications/cursor.desktop")
    ICON_PATH = Path("/usr/share/pixmaps/cursor.png")
    
    # User Paths - Version management system
    CURSOR_DIR = Path.home() / ".local" / "share" / "cursor-installer"
    DOWNLOADS_DIR = CURSOR_DIR / "versions"
    CACHE_FILE = CURSOR_DIR / "versions_cache.json"
    CACHE_DURATION_MINUTES = 60  # Longer cache for dynamic discovery
    
    # Backup Paths
    BACKUP_DIR = Path.home() / "Applications" / "cursor" / "backups"
    CONFIG_DIR = Path.home() / ".cursor"
    
    def __init__(self):
        """Initialize the installer with session and directories."""
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Cursor-Update/1.1.1 (Linux)'
        })
        
        # Create directories
        self.CURSOR_DIR.mkdir(parents=True, exist_ok=True)
        self.DOWNLOADS_DIR.mkdir(parents=True, exist_ok=True)
        self.BACKUP_DIR.mkdir(parents=True, exist_ok=True)

    def print_color(self, color: str, message: str):
        """Print colored message."""
        print(f"{color}{message}{Colors.NC}")

    def print_success(self, message: str):
        """Print success message."""
        self.print_color(Colors.GREEN, f"✓ {message}")

    def print_warning(self, message: str):
        """Print warning message."""
        self.print_color(Colors.ORANGE, f"⚠ {message}")

    def print_error(self, message: str):
        """Print error message."""
        self.print_color(Colors.RED, f"✗ {message}")

    def print_info(self, message: str):
        """Print info message."""
        self.print_color(Colors.BLUE, f"ℹ {message}")

    def detect_architecture(self) -> str:
        """Detect system architecture."""
        import platform
        arch = platform.machine().lower()
        
        if arch in ['x86_64', 'amd64']:
            return 'x64'
        elif arch in ['aarch64', 'arm64']:
            return 'arm64'
        else:
            self.print_warning(f"Unknown architecture: {arch}, defaulting to x64")
            return 'x64'

    def is_cache_valid(self) -> bool:
        """Check if cache file exists and is still valid."""
        if not self.CACHE_FILE.exists():
            return False
        cache_time = datetime.fromtimestamp(self.CACHE_FILE.stat().st_mtime)
        now = datetime.now()
        return (now - cache_time) < timedelta(minutes=self.CACHE_DURATION_MINUTES)

    def load_cached_versions(self) -> Optional[List[Dict[str, str]]]:
        """Load versions from cache if valid and contains recent versions."""
        if self.is_cache_valid():
            try:
                with open(self.CACHE_FILE, 'r') as f:
                    cached_data = json.load(f)
                    
                # Check if cache is reasonably fresh and has enough versions
                if cached_data:
                    if len(cached_data) < 5:
                        self.print_info("Cache has too few versions, refreshing...")
                        return None
                    
                    # Check cache age - force refresh if older than 6 hours for dynamic discovery
                    cache_time = datetime.fromtimestamp(self.CACHE_FILE.stat().st_mtime)
                    now = datetime.now()
                    if (now - cache_time) > timedelta(hours=6):
                        self.print_info("Cache is older than 6 hours, refreshing for latest versions...")
                        return None
                    
                return cached_data
            except (json.JSONDecodeError, FileNotFoundError):
                pass
        return None

    def save_versions_cache(self, versions: List[Dict[str, str]]):
        """Save versions to cache."""
        try:
            with open(self.CACHE_FILE, 'w') as f:
                json.dump(versions, f, indent=2)
        except Exception as e:
            self.print_warning(f"Could not save cache: {e}")

    def get_latest_version_from_api(self) -> Dict[str, str]:
        """Get the latest version info from Cursor's official API."""
        arch = self.detect_architecture()
        platform = 'linux-x64' if arch == 'x64' else 'linux-arm64'
        
        # Try multiple API endpoints
        api_endpoints = [
            f"https://www.cursor.com/api/download?platform={platform}&releaseTrack=stable",
            f"https://api.cursor.com/download?platform={platform}&releaseTrack=stable",
            "https://api.github.com/repos/getcursor/cursor/releases/latest"
        ]
        
        for api_url in api_endpoints:
            try:
                self.print_info(f"🔍 Fetching latest version from API: {api_url}")
                
                response = self.session.get(api_url, timeout=10)
                response.raise_for_status()
                
                data = response.json()
                
                # Handle different API response formats
                if 'downloadUrl' in data and 'version' in data:
                    # Official Cursor API format
                    version_str = data.get('version')
                    download_url = data.get('downloadUrl')
                elif 'tag_name' in data:
                    # GitHub API format
                    version_str = data.get('tag_name', '').replace('v', '')
                    # Construct download URL for GitHub releases
                    download_url = f"https://downloads.cursor.com/production/a1fa6fc7d2c2f520293aad84aaa38d091dee6fef/linux/x64/Cursor-{version_str}-x86_64.AppImage"
                else:
                    continue
                
                if version_str:
                    self.print_success(f"Found latest version from API: v{version_str}")
                    return {
                        'version': version_str,
                        'tag_name': f"v{version_str}",
                        'published_at': 'Latest',
                        'download_url': download_url
                    }
                    
            except Exception as e:
                self.print_warning(f"API request to {api_url} failed: {e}")
                continue
        
        return None

    def discover_versions_by_probing(self) -> List[Dict[str, str]]:
        """Discover available versions by probing Cursor's download URLs dynamically."""
        arch = self.detect_architecture()
        arch_path = 'x64' if arch == 'x64' else 'arm64'
        arch_suffix = 'x86_64' if arch == 'x64' else 'arm64'
        
        discovered_versions = []
        
        # First, try to get the latest version from the official API
        latest_from_api = self.get_latest_version_from_api()
        if latest_from_api:
            discovered_versions.append(latest_from_api)
        
        self.print_info("🔍 Dynamic version discovery - testing for more versions")
        self.print_info(f"Architecture: {arch} ({arch_path}, {arch_suffix})")
        
        # URL patterns to test (in order of preference)
        url_patterns = [
            f"https://downloads.cursor.com/production/latest/linux/{arch_path}/Cursor-{{version}}-{arch_suffix}.AppImage",
            f"https://downloads.cursor.com/production/{{version}}/linux/{arch_path}/Cursor-{{version}}-{arch_suffix}.AppImage", 
            f"https://downloads.cursor.com/linux/{arch_path}/Cursor-{{version}}-{arch_suffix}.AppImage"
        ]
        
        # Only do extensive probing if we don't have the API version
        if not latest_from_api:
            self.print_warning("API failed, falling back to probing method...")
            # Version series to test (from newest to oldest, expanded ranges for latest versions)
            version_series = [
                # Test potential newer versions first
                {"major": 1, "minor": 4, "patch_range": range(0, 10)}, # 1.4.0 - 1.4.9
                {"major": 1, "minor": 3, "patch_range": range(0, 20)}, # 1.3.0 - 1.3.19 (expanded)
                {"major": 1, "minor": 2, "patch_range": range(0, 15)}, # 1.2.0 - 1.2.14 (expanded)
                {"major": 1, "minor": 1, "patch_range": range(0, 10)}, # 1.1.0 - 1.1.9
                {"major": 1, "minor": 0, "patch_range": range(0, 10)}, # 1.0.0 - 1.0.9
            ]
            
            for series in version_series:
                # All series use patch_range (simplified)
                for patch in series["patch_range"]:
                    version = f"{series['major']}.{series['minor']}.{patch}"
                    if self._test_version(version, url_patterns, arch_path, arch_suffix):
                        discovered_versions.append({
                            'version': version,
                            'tag_name': f"v{version}",
                            'published_at': 'Available',
                            'download_url': self._get_working_url(version, url_patterns, arch_path, arch_suffix)
                        })
                        self.print_info(f"  ✓ Found {version}")
                        if len(discovered_versions) >= 12:  # Get 12 to ensure we have 10 good ones after sorting
                            break
                
                if len(discovered_versions) >= 12:
                    break
        else:
            # We have the latest from API, probe for newer versions and recent stable ones
            self.print_info("API provided latest version, probing for newer and stable versions...")
            recent_versions = [
                # Test potential newer versions first
                "1.4.5", "1.4.4", "1.4.3", "1.4.2", "1.4.1", "1.4.0",
                "1.3.15", "1.3.14", "1.3.13", "1.3.12", "1.3.11", "1.3.10", "1.3.9",
                "1.3.8", "1.3.7", "1.3.6", "1.3.5", "1.3.4", "1.3.3", "1.3.2", "1.3.1", "1.3.0",
                "1.2.9", "1.2.8", "1.2.7"
            ]
            for version in recent_versions:
                if self._test_version(version, url_patterns, arch_path, arch_suffix):
                    # Check if we already have this version from API
                    if not any(v['version'] == version for v in discovered_versions):
                        discovered_versions.append({
                            'version': version,
                            'tag_name': f"v{version}",
                            'published_at': 'Available',
                            'download_url': self._get_working_url(version, url_patterns, arch_path, arch_suffix)
                        })
                        self.print_info(f"  ✓ Found {version}")
                if len(discovered_versions) >= 8:  # Limit when we have API version
                    break
        
        # Sort by version (newest first) and limit to top 10
        try:
            from packaging import version as pkg_version
            discovered_versions.sort(key=lambda x: pkg_version.parse(x['version']), reverse=True)
        except Exception:
            # Fallback to string sorting
            discovered_versions.sort(key=lambda x: x['version'], reverse=True)
        
        # Keep only the latest 10 versions
        discovered_versions = discovered_versions[:10]
        
        self.print_success(f"🎯 Discovered {len(discovered_versions)} latest versions")
        for i, v in enumerate(discovered_versions[:5], 1):
            self.print_info(f"  {i}. v{v['version']} ({v['published_at']})")
        if len(discovered_versions) > 5:
            self.print_info(f"  ... and {len(discovered_versions) - 5} more versions")
        
        return discovered_versions
    
    def _test_version(self, version: str, url_patterns: List[str], arch_path: str, arch_suffix: str) -> bool:
        """Test if a specific version exists and is downloadable using any of the URL patterns."""
        for pattern in url_patterns:
            test_url = pattern.format(version=version)
            try:
                response = self.session.head(test_url, timeout=4)  # Faster timeout
                # Only consider 200 and redirects as valid, NOT 403 (Forbidden)
                if response.status_code in [200, 301, 302]:
                    return True
            except Exception:
                continue
        return False
    
    def _get_working_url(self, version: str, url_patterns: List[str], arch_path: str, arch_suffix: str) -> str:
        """Get the first working URL for a version."""
        for pattern in url_patterns:
            test_url = pattern.format(version=version)
            try:
                response = self.session.head(test_url, timeout=4)  # Faster timeout
                # Only return URLs that are actually downloadable (not 403)
                if response.status_code in [200, 301, 302]:
                    return test_url
            except Exception:
                continue
        # Fallback to first pattern if none work
        return url_patterns[0].format(version=version)

    def fetch_available_versions(self, force_refresh: bool = False) -> List[Dict[str, str]]:
        """Fetch available Cursor versions with intelligent probing and fallback."""
        if force_refresh:
            self.print_info("Force refresh requested, skipping cache...")
            cached_versions = None
        else:
            cached_versions = self.load_cached_versions()
            if cached_versions:
                self.print_info("Using cached version information")
                return cached_versions

        # Always use dynamic probing - no fallbacks
        try:
            self.print_info("🚀 Starting dynamic version discovery...")
            versions = self.discover_versions_by_probing()
            if versions:
                # Remove duplicates while preserving order
                seen = set()
                unique_versions = []
                for v in versions:
                    version_key = v['version']
                    if version_key not in seen:
                        seen.add(version_key)
                        unique_versions.append(v)
                
                self.save_versions_cache(unique_versions)
                return unique_versions
        except Exception as e:
            self.print_error(f"Dynamic version discovery failed: {e}")
            import traceback
            self.print_warning(f"Traceback: {traceback.format_exc()}")

        # If dynamic discovery completely fails, use minimal fallback
        self.print_warning("❌ Dynamic discovery failed, using emergency fallback versions")
        self.print_info("This could be due to:")
        self.print_info("  • Network connectivity issues")
        self.print_info("  • Cursor download server changes")
        self.print_info("  • Firewall/proxy blocking requests")
        
        # Emergency fallback - try API once more, then hardcoded versions
        self.print_info("🆘 Attempting emergency API call...")
        emergency_api_version = self.get_latest_version_from_api()
        
        emergency_versions = []
        if emergency_api_version:
            emergency_versions.append(emergency_api_version)
            self.print_success("Emergency API call succeeded!")
        else:
            # Last resort hardcoded versions with API URLs when possible
            arch = self.detect_architecture()
            platform = 'linux-x64' if arch == 'x64' else 'linux-arm64'
            
            hardcoded_versions = [
                # Try API first, then known working versions
                ("latest", f"https://www.cursor.com/api/download?platform={platform}&releaseTrack=stable"),
                ("1.3.6", "https://downloads.cursor.com/linux/x64/Cursor-1.3.6-x86_64.AppImage"),
                ("1.3.5", "https://downloads.cursor.com/linux/x64/Cursor-1.3.5-x86_64.AppImage"),
                ("1.3.4", "https://downloads.cursor.com/linux/x64/Cursor-1.3.4-x86_64.AppImage"),
            ]
            
            for ver, url in hardcoded_versions:
                # For API URLs, try to get the real download URL
                if 'api/download' in url:
                    try:
                        response = self.session.get(url, timeout=5)
                        if response.status_code == 200:
                            data = response.json()
                            real_url = data.get('downloadUrl')
                            real_version = data.get('version', ver)
                            if real_url:
                                emergency_versions.append({
                                    'version': real_version,
                                    'tag_name': f"v{real_version}",
                                    'published_at': 'Emergency API',
                                    'download_url': real_url
                                })
                                continue
                    except Exception:
                        pass
                
                # Fallback to hardcoded
                emergency_versions.append({
                    'version': ver,
                    'tag_name': f"v{ver}",
                    'published_at': 'Emergency',
                    'download_url': url
                })
        
        self.print_info(f"Using emergency fallback with {len(emergency_versions)} versions")
        return emergency_versions

    def list_versions(self, limit: int = 20, force_refresh: bool = False):
        """List available Cursor versions with enhanced display."""
        versions = self.fetch_available_versions(force_refresh=force_refresh)
        if not versions:
            self.print_error("No versions found. Please check your internet connection.")
            return

        local_versions = self.get_local_versions()
        active_version = self.get_active_version()

        self.print_color(Colors.BOLD + Colors.CYAN, f"\n📋 Available Cursor IDE Versions (showing {min(limit, len(versions))} of {len(versions)}):\n")

        for i, version in enumerate(versions[:limit]):
            version_num = version.get('version', version.get('tag_name', 'Unknown')).lstrip('v')
            date = version.get('published_at', 'Unknown date')
            
            # Status indicators
            status_indicators = []
            if version_num in local_versions:
                status_indicators.append(f"{Colors.GREEN}DOWNLOADED{Colors.NC}")
                
            if active_version and active_version == version_num:
                status_indicators.append(f"{Colors.PURPLE}ACTIVE{Colors.NC}")
            
            status_text = f" [{', '.join(status_indicators)}]" if status_indicators else ""
            
            # Version line
            print(f"  {Colors.CYAN}{i+1:2d}.{Colors.NC} v{version_num} ({date}){status_text}")

        print(f"\n{Colors.BLUE}ℹ{Colors.NC} Use 'download <version>' to download a version")
        print(f"{Colors.BLUE}ℹ{Colors.NC} Use 'use <version>' to switch between downloaded versions")

    def get_local_versions(self) -> List[str]:
        """Get list of locally downloaded version numbers."""
        if not self.DOWNLOADS_DIR.exists():
            return []
        
        versions = []
        for file_path in self.DOWNLOADS_DIR.glob("*[Cc]ursor*.AppImage"):
            # Improved regex to handle Cursor/cursor, semantic version (x.y.z), optional arch suffix
            match = re.search(r'[Cc]ursor-(\d+\.\d+\.\d+)(?:-[a-z0-9_]+)?\.AppImage$', file_path.name, re.IGNORECASE)
            if match:
                version_str = match.group(1)
                versions.append(version_str)
        
        # Sort versions, handling potential parsing errors gracefully
        try:
            return sorted(versions, key=lambda v: version.parse(v), reverse=True)
        except Exception:
            return sorted(versions, reverse=True)

    def get_active_version(self) -> Optional[str]:
        """Get the currently active version from symlink."""
        active_symlink = self.CURSOR_DIR / "active"
        
        if not active_symlink.exists() or not active_symlink.is_symlink():
            return None
        
        try:
            target_path = active_symlink.resolve()
            # Extract version from filename with improved regex
            match = re.search(r'[Cc]ursor-(\d+\.\d+\.\d+)(?:-[a-z0-9_]+)?\.AppImage$', target_path.name, re.IGNORECASE)
            if match:
                return match.group(1)
        except Exception:
            pass
        
        return None

    def download_version(self, version: str, destination: Path = None) -> bool:
        """Download a specific version to the versions directory."""
        versions = self.fetch_available_versions()
        if not versions:
            self.print_error("No versions available for download")
            return False

        # Find the requested version
        selected_version = None
        for v in versions:
            # Support both "v1.0.0" and "1.0.0" formats
            version_tag = v.get('tag_name', '').lstrip('v')
            if version_tag == version.lstrip('v') or v.get('version', '') == version.lstrip('v'):
                selected_version = v
                break

        if not selected_version:
            self.print_error(f"Version {version} not found")
            self.print_info("Use 'list' command to see available versions")
            return False

        download_url = selected_version.get('download_url')
        if not download_url:
            self.print_error(f"No download URL found for version {version}")
            return False

        # Extract filename from URL
        filename = os.path.basename(urlparse(download_url).path)
        if destination is None:
            destination = self.DOWNLOADS_DIR / filename
        else:
            destination = Path(destination)

        # Check if already downloaded
        if destination.exists():
            self.print_warning(f"Version {version} already downloaded at {destination}")
            return True

        # Ensure destination directory exists
        destination.parent.mkdir(parents=True, exist_ok=True)

        # Download
        self.print_info(f"Downloading Cursor v{version}...")
        self.print_info(f"Source: {download_url}")
        self.print_info(f"Destination: {destination}")

        try:
            response = self.session.get(download_url, stream=True, timeout=30)
            response.raise_for_status()

            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0

            with open(destination, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        
                        if total_size > 0:
                            progress = (downloaded / total_size) * 100
                            speed = downloaded / (1024 * 1024)  # MB downloaded
                            print(f"\r{Colors.BLUE}ℹ{Colors.NC} Progress: {progress:.1f}% ({speed:.1f} MB downloaded)", end='', flush=True)

            print()  # New line after progress
            
            # Make executable
            destination.chmod(0o755)
            
            self.print_success(f"Downloaded Cursor v{version} to {destination}")
            return True

        except requests.exceptions.RequestException as e:
            self.print_error(f"Download failed: {e}")
            if destination.exists():
                destination.unlink()
            return False
        except Exception as e:
            self.print_error(f"Unexpected error during download: {e}")
            if destination.exists():
                destination.unlink()
            return False

    def use_version(self, version: str) -> bool:
        """Switch to a specific downloaded version."""
        version = version.lstrip('v')
        local_versions = self.get_local_versions()
        
        if version not in local_versions:
            self.print_error(f"Version {version} is not downloaded locally")
            self.print_info("Use 'download' command to download it first")
            return False
        
        # Find the AppImage file for this version
        matching_files = []
        for file in self.DOWNLOADS_DIR.glob("*[Cc]ursor*.AppImage"):
            match = re.search(r'[Cc]ursor-(\d+\.\d+\.\d+)(?:-[a-z0-9_]+)?\.AppImage$', file.name, re.IGNORECASE)
            if match and match.group(1) == version:
                matching_files.append(file)
        
        if not matching_files:
            self.print_error(f"AppImage file not found for version {version}")
            return False
        
        appimage_path = matching_files[0]  # Take the first matching file
        
        # Create symlink for active version management
        active_symlink = self.CURSOR_DIR / "active"
        
        # Remove existing symlink
        if active_symlink.exists():
            active_symlink.unlink()
        
        # Create new symlink
        try:
            active_symlink.symlink_to(appimage_path)
            self.print_success(f"Switched to Cursor v{version}")
            
            # Update system installation if it exists
            if self.SYSTEM_INSTALL_PATH.exists():
                self.print_info("Updating system installation...")
                try:
                    subprocess.run(['sudo', 'cp', '-p', str(appimage_path), str(self.SYSTEM_INSTALL_PATH)], check=True)
                    subprocess.run(['sudo', 'chmod', '0755', str(self.SYSTEM_INSTALL_PATH)], check=True)
                    self.print_success("System installation updated")
                except subprocess.CalledProcessError as e:
                    self.print_warning(f"Failed to update system installation: {e}")
                except Exception as e:
                    self.print_warning(f"Failed to update system installation: {e}")
            
            return True
            
        except Exception as e:
            self.print_error(f"Failed to switch version: {e}")
            return False

    def remove_version(self, version: str) -> bool:
        """Remove a specific downloaded version."""
        version = version.lstrip('v')
        local_versions = self.get_local_versions()
        
        if version not in local_versions:
            self.print_error(f"Version {version} is not downloaded locally")
            return False
        
        # Find the AppImage file for this version
        matching_files = []
        for file in self.DOWNLOADS_DIR.glob("*[Cc]ursor*.AppImage"):
            match = re.search(r'[Cc]ursor-(\d+\.\d+\.\d+)(?:-[a-z0-9_]+)?\.AppImage$', file.name, re.IGNORECASE)
            if match and match.group(1) == version:
                matching_files.append(file)
        
        if not matching_files:
            self.print_error(f"AppImage file not found for version {version}")
            return False
        
        try:
            for file in matching_files:
                file.unlink()
                self.print_success(f"Removed file {file}")
            
            active_version = self.get_active_version()
            if active_version == version:
                (self.CURSOR_DIR / "active").unlink(missing_ok=True)
                self.print_info(f"Removed active symlink for version {version}")
            
            self.print_success(f"Removed version {version}")
            return True
        except Exception as e:
            self.print_error(f"Failed to remove version {version}: {e}")
            return False

    def install_latest(self, force: bool = False) -> bool:
        """Install the latest version system-wide."""
        # First, download the latest version
        versions = self.fetch_available_versions()
        if not versions:
            self.print_error("Cannot fetch version information")
            return False
        
        latest_version = versions[0]['version']
        
        # Download if not already downloaded
        if not self.download_version(latest_version):
            return False
        
        # Use the version (creates symlink)
        if not self.use_version(latest_version):
            return False
        
        # Now install system-wide
        return self._install_system_wide(latest_version, force)

    def _install_system_wide(self, version: str, force: bool = False) -> bool:
        """Install a downloaded version system-wide."""
        # Find the AppImage file
        matching_files = []
        for file in self.DOWNLOADS_DIR.glob("*[Cc]ursor*.AppImage"):
            match = re.search(r'[Cc]ursor-(\d+\.\d+\.\d+)(?:-[a-z0-9_]+)?\.AppImage$', file.name, re.IGNORECASE)
            if match and match.group(1) == version:
                matching_files.append(file)
        
        if not matching_files:
            self.print_error(f"Version {version} not found locally")
            return False
        
        appimage_path = matching_files[0]
        
        try:
            # Create backup if existing installation
            if self.SYSTEM_INSTALL_PATH.exists():
                self.print_info("Creating backup of existing installation...")
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                backup_path = self.BACKUP_DIR / f"cursor_backup_{timestamp}.AppImage"
                subprocess.run(['sudo', 'cp', '-p', str(self.SYSTEM_INSTALL_PATH), str(backup_path)], check=True)
                self.print_success(f"Backup created: {backup_path}")
            
            # Copy to system location
            self.print_info("Installing to system location...")
            subprocess.run(['sudo', 'cp', '-p', str(appimage_path), str(self.SYSTEM_INSTALL_PATH)], check=True)
            subprocess.run(['sudo', 'chmod', '0755', str(self.SYSTEM_INSTALL_PATH)], check=True)
            
            # Create desktop integration
            self._create_desktop_integration()
            
            # Install shell integration
            self._install_shell_integration()
            
            self.print_success(f"Cursor v{version} installed successfully!")
            self.print_info("You can now launch Cursor from:")
            self.print_info("  - Applications menu")
            self.print_info("  - Terminal: cursor")
            self.print_info(f"  - Direct: {self.SYSTEM_INSTALL_PATH}")
            
            return True
            
        except subprocess.CalledProcessError as e:
            self.print_error(f"System installation failed: {e}. You may need to provide sudo password or check permissions.")
            return False
        except Exception as e:
            self.print_error(f"Installation failed: {e}")
            return False

    def _extract_icon_from_appimage(self, appimage_path: Path) -> bool:
        """Extract icon from AppImage using --appimage-extract."""
        try:
            self.print_info("Extracting icon from AppImage...")
            
            # Create temporary directory for extraction
            with tempfile.TemporaryDirectory() as temp_dir:
                temp_path = Path(temp_dir)
                
                # Extract only the icon files from AppImage
                extract_cmd = [str(appimage_path), '--appimage-extract', '*.png']
                result = subprocess.run(extract_cmd, cwd=temp_path, capture_output=True, text=True)
                
                if result.returncode != 0:
                    # Fallback: extract usr/share/icons
                    extract_cmd = [str(appimage_path), '--appimage-extract', 'usr/share/icons/*/*cursor*']
                    result = subprocess.run(extract_cmd, cwd=temp_path, capture_output=True, text=True)
                
                if result.returncode != 0:
                    # Second fallback: extract resources folder
                    extract_cmd = [str(appimage_path), '--appimage-extract', 'usr/share/cursor/resources/*icon*']
                    result = subprocess.run(extract_cmd, cwd=temp_path, capture_output=True, text=True)
                
                # Look for extracted icon files
                squashfs_root = temp_path / 'squashfs-root'
                if squashfs_root.exists():
                    # Search for icon files in common locations
                    icon_locations = [
                        'usr/share/icons/hicolor/*/apps/cursor.png',
                        'usr/share/pixmaps/cursor.png', 
                        'usr/share/cursor/resources/app/resources/cursor.png',
                        'usr/share/cursor/resources/app/resources/linux/icon.png',
                        'resources/app/resources/cursor.png',
                        '*.png'
                    ]
                    
                    found_icon = None
                    for pattern in icon_locations:
                        matches = list(squashfs_root.glob(pattern))
                        if matches:
                            # Prefer larger icons (check file size)
                            found_icon = max(matches, key=lambda p: p.stat().st_size if p.exists() else 0)
                            break
                    
                    if found_icon and found_icon.exists():
                        # Copy icon to system location
                        subprocess.run(['sudo', 'cp', str(found_icon), str(self.ICON_PATH)], check=True)
                        subprocess.run(['sudo', 'chmod', '0644', str(self.ICON_PATH)], check=True)
                        self.print_success(f"Icon extracted from AppImage: {found_icon.name}")
                        return True
                
                self.print_warning("No suitable icon found in AppImage")
                return False
                
        except Exception as e:
            self.print_warning(f"Icon extraction failed: {e}")
            return False

    def _download_fallback_icon(self):
        """Download fallback icon if extraction fails."""
        try:
            self.print_info("Downloading fallback icon...")
            # Try multiple icon sources
            icon_urls = [
                "https://raw.githubusercontent.com/getcursor/cursor/main/resources/cursor.png",
                "https://www.cursor.com/favicon-32x32.png",
                "https://avatars.githubusercontent.com/u/140930462?s=200&v=4"  # Cursor GitHub avatar
            ]
            
            for icon_url in icon_urls:
                try:
                    response = self.session.get(icon_url, timeout=10)
                    if response.status_code == 200 and len(response.content) > 1000:  # Ensure it's a real image
                        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
                            temp_file.write(response.content)
                        temp_path = Path(temp_file.name)
                        subprocess.run(['sudo', 'mv', str(temp_path), str(self.ICON_PATH)], check=True)
                        subprocess.run(['sudo', 'chmod', '0644', str(self.ICON_PATH)], check=True)
                        self.print_success("Fallback icon downloaded")
                        return True
                except Exception:
                    continue
            
            self.print_warning("All fallback icon sources failed")
            return False
            
        except Exception as e:
            self.print_warning(f"Fallback icon download failed: {e}")
            return False

    def _is_our_desktop_file(self, desktop_file_path):
        """Check if a desktop file follows our standard pattern."""
        try:
            with open(desktop_file_path, 'r') as f:
                content = f.read()
            
            # Check for our signature patterns
            our_patterns = [
                "Comment=The AI-first code editor. Edit code with AI superpowers.",
                "StartupWMClass=cursor",
                "Keywords=cursor;code;editor;ide;development;programming;ai;copilot",
                "--no-sandbox %F"
            ]
            
            # All patterns must be present for it to be our file
            for pattern in our_patterns:
                if pattern not in content:
                    return False
                    
            return True
        except Exception:
            return False

    def _create_desktop_integration(self):
        """Create enhanced desktop shortcut with proper icon extraction."""
        self.print_info("Creating desktop integration...")
        
        # Check for conflicting desktop entries (but be selective)
        self.print_info("Checking for conflicting desktop entries...")
        import subprocess
        import glob
        import os
        import time
        
        # Remove existing cursor desktop files (but preserve recent ones)
        existing_desktop_files = []
        for pattern in ["/usr/share/applications/*cursor*.desktop", "/usr/share/applications/*Cursor*.desktop"]:
            existing_desktop_files.extend(glob.glob(pattern))
        
        if existing_desktop_files:
            self.print_info(f"Found {len(existing_desktop_files)} existing desktop entries to analyze")
            removed_count = 0
            updated_count = 0
            for desktop_file in existing_desktop_files:
                try:
                    # Check if desktop file follows our standard pattern
                    if self._is_our_desktop_file(desktop_file):
                        self.print_info(f"  • Found our standard file: {desktop_file} - will update it")
                        updated_count += 1
                        # Don't remove it, will be updated when we create the new one
                    else:
                        subprocess.run(['sudo', 'rm', '-f', desktop_file], check=True, capture_output=True)
                        self.print_info(f"  • Removed non-standard entry: {desktop_file}")
                        removed_count += 1
                except Exception as e:
                    self.print_warning(f"Failed to process {desktop_file}: {e}")
            if removed_count == 0 and updated_count == 0:
                self.print_info("No desktop entries processed")
            elif removed_count == 0:
                self.print_info(f"Found {updated_count} standard entries to update")
            elif updated_count == 0:
                self.print_info(f"Removed {removed_count} non-standard entries")
        else:
            self.print_info("No existing desktop entries found")
        
        # Also check user-specific applications directory (pattern-based analysis)
        user_apps_dir = Path.home() / ".local/share/applications"
        if user_apps_dir.exists():
            user_desktop_files = list(user_apps_dir.glob("*cursor*.desktop")) + list(user_apps_dir.glob("*Cursor*.desktop"))
            if user_desktop_files:
                self.print_info(f"Found {len(user_desktop_files)} user desktop entries to analyze")
                removed_count = 0
                updated_count = 0
                for desktop_file in user_desktop_files:
                    try:
                        # Check if desktop file follows our standard pattern
                        if self._is_our_desktop_file(str(desktop_file)):
                            self.print_info(f"  • Found our standard user file: {desktop_file} - will update it")
                            updated_count += 1
                            # Don't remove it, will be updated when we create the new one
                        else:
                            desktop_file.unlink()
                            self.print_info(f"  • Removed non-standard user entry: {desktop_file}")
                            removed_count += 1
                    except Exception as e:
                        self.print_warning(f"Failed to process {desktop_file}: {e}")
                if removed_count == 0 and updated_count == 0:
                    self.print_info("No user desktop entries processed")
                elif removed_count == 0:
                    self.print_info(f"Found {updated_count} standard user entries to update")
                elif updated_count == 0:
                    self.print_info(f"Removed {removed_count} non-standard user entries")
        
        # Force desktop database update to clear old entries
        try:
            subprocess.run(['sudo', 'update-desktop-database', '/usr/share/applications/'], 
                         capture_output=True, check=False)
            if user_apps_dir.exists():
                subprocess.run(['update-desktop-database', str(user_apps_dir)], 
                             capture_output=True, check=False)
        except Exception:
            pass
        
        # First try to extract icon from AppImage
        icon_extracted = False
        if self.SYSTEM_INSTALL_PATH.exists():
            self.print_info(f"Extracting icon from {self.SYSTEM_INSTALL_PATH}...")
            icon_extracted = self._extract_icon_from_appimage(self.SYSTEM_INSTALL_PATH)
        else:
            self.print_warning(f"AppImage not found at {self.SYSTEM_INSTALL_PATH}")
        
        # If extraction failed, try fallback download
        if not icon_extracted:
            self.print_info("Icon extraction failed, trying fallback...")
            icon_extracted = self._download_fallback_icon()
            
        if not icon_extracted:
            self.print_warning("No icon could be obtained, using text-based entry")
        
        # Enhanced desktop file with better file associations and categories
        # Fixed format - no trailing semicolons, proper escaping
        desktop_content = f"""[Desktop Entry]
Version=1.0
Name=Cursor
GenericName=Code Editor
Comment=The AI-first code editor. Edit code with AI superpowers.
Exec={self.SYSTEM_INSTALL_PATH} --no-sandbox %F
Icon={self.ICON_PATH if icon_extracted else 'text-editor'}
Type=Application
Categories=Development;TextEditor;IDE;Programming
MimeType=text/plain;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;text/x-java;text/x-dsrc;text/x-pascal;text/x-perl;text/x-python;application/x-php;application/javascript;application/json;text/css;text/html;application/xhtml+xml;text/xml;text/x-yaml;text/markdown;inode/directory
Keywords=cursor;code;editor;ide;development;programming;ai;copilot
StartupNotify=true
StartupWMClass=cursor
Terminal=false
NoDisplay=false
"""

        try:
            # Ensure the applications directory exists
            apps_dir = Path("/usr/share/applications")
            if not apps_dir.exists():
                self.print_warning(f"Applications directory {apps_dir} does not exist")
                return False
                
            self.print_info(f"Creating desktop file at {self.DESKTOP_FILE_PATH}...")
            with tempfile.NamedTemporaryFile(delete=False, mode='w') as temp_file:
                temp_file.write(desktop_content)
            temp_path = Path(temp_file.name)
            
            # Copy and set permissions
            result = subprocess.run(['sudo', 'cp', str(temp_path), str(self.DESKTOP_FILE_PATH)], 
                                  capture_output=True, text=True)
            if result.returncode != 0:
                self.print_error(f"Failed to copy desktop file: {result.stderr}")
                return False
                
            subprocess.run(['sudo', 'chmod', '0644', str(self.DESKTOP_FILE_PATH)], 
                         capture_output=True, check=False)
            
            # Clean up temp file
            temp_path.unlink(missing_ok=True)
            
            self.print_success(f"Desktop file created: {self.DESKTOP_FILE_PATH}")
            
            # Verify file was created
            if not self.DESKTOP_FILE_PATH.exists():
                self.print_error("Desktop file was not created successfully")
                return False
            
            # Comprehensive desktop database updates
            self.print_info("Updating desktop databases...")
            
            # Update desktop database (most important)
            result = subprocess.run(['sudo', 'update-desktop-database', '/usr/share/applications/'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                self.print_success("Desktop database updated")
            else:
                self.print_warning(f"Desktop database update failed: {result.stderr}")
            
            # Update MIME database 
            subprocess.run(['sudo', 'update-mime-database', '/usr/share/mime/'], 
                         capture_output=True, check=False)
            
            # Force update desktop menu
            subprocess.run(['xdg-desktop-menu', 'forceupdate'], capture_output=True, check=False)
            
            # Update icon cache if icon was installed
            if icon_extracted and self.ICON_PATH.exists():
                subprocess.run(['sudo', 'gtk-update-icon-cache', '-f', '/usr/share/pixmaps/'], 
                             capture_output=True, check=False)
                subprocess.run(['sudo', 'gtk-update-icon-cache', '-f', '/usr/share/icons/hicolor/'], 
                             capture_output=True, check=False)
                self.print_success("Icon cache updated")
            
            # Test if desktop file is valid
            result = subprocess.run(['desktop-file-validate', str(self.DESKTOP_FILE_PATH)], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                self.print_success("Desktop file validation passed")
            else:
                self.print_warning(f"Desktop file validation issues: {result.stderr}")
                self.print_info("Desktop file content:")
                self.print_info("=" * 50)
                try:
                    with open(self.DESKTOP_FILE_PATH, 'r') as f:
                        content = f.read()
                        for i, line in enumerate(content.split('\n'), 1):
                            self.print_info(f"{i:2d}: {line}")
                except Exception as e:
                    self.print_warning(f"Could not read desktop file: {e}")
                self.print_info("=" * 50)
            
            # Force immediate desktop database refresh
            self.print_info("Forcing desktop environment refresh...")
            subprocess.run(['sudo', 'update-desktop-database', '/usr/share/applications/'], 
                         capture_output=True, check=False)
            
            # Check if file persists after 2 seconds
            import time
            time.sleep(2)
            
            if self.DESKTOP_FILE_PATH.exists():
                self.print_success(f"Desktop file still exists after 2 seconds: {self.DESKTOP_FILE_PATH}")
                
                # Check file permissions
                stat_result = subprocess.run(['ls', '-la', str(self.DESKTOP_FILE_PATH)], 
                                           capture_output=True, text=True)
                self.print_info(f"File permissions: {stat_result.stdout.strip()}")
                
                # Try to detect desktop entries
                result = subprocess.run(['grep', '-l', 'Cursor', '/usr/share/applications/*.desktop'], 
                                      capture_output=True, text=True, shell=True)
                if result.returncode == 0:
                    self.print_success(f"Desktop file found in system: {result.stdout.strip()}")
                else:
                    self.print_warning("Desktop file not found by grep search")
                
            else:
                self.print_error("Desktop file disappeared after 2 seconds!")
                return False
            
            self.print_success("Desktop integration completed successfully!")
            self.print_info("You should now see Cursor in your applications menu")
            self.print_info("If not visible immediately, try: Alt+F2, then type 'cursor'")
            return True
            
        except Exception as e:
            self.print_error(f"Desktop integration failed: {e}")
            import traceback
            self.print_warning(f"Traceback: {traceback.format_exc()}")
            return False

    def _install_shell_integration(self):
        """Install shell integration (cursor command)."""
        # Create a simple wrapper script
        cursor_script_content = f"""#!/bin/bash
exec {self.SYSTEM_INSTALL_PATH} --no-sandbox "$@"
"""
        
        try:
            with tempfile.NamedTemporaryFile(delete=False, mode='w') as temp_file:
                temp_file.write(cursor_script_content)
            temp_path = Path(temp_file.name)
            cursor_bin = "/usr/local/bin/cursor"
            subprocess.run(['sudo', 'mv', str(temp_path), cursor_bin], check=True)
            subprocess.run(['sudo', 'chmod', '0755', cursor_bin], check=True)
            self.print_success("Shell integration installed (cursor command available)")
        except Exception as e:
            self.print_warning(f"Could not install shell integration: {e}")

def main():
    """Main entry point for the embedded installer."""
    parser = argparse.ArgumentParser(
        description="Cursor IDE Installer - Embedded Version",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('action', choices=['list', 'download', 'install', 'use', 'remove', 'active'], 
                       help='Action to perform')
    parser.add_argument('version', nargs='?', help='Version to download/install/use/remove')
    parser.add_argument('--force', action='store_true', help='Force installation')
    
    args = parser.parse_args()
    
    installer = CursorInstaller()
    
    if args.action == 'list':
        installer.list_versions()
    elif args.action == 'download':
        if not args.version:
            installer.print_error("Version required for download")
            return 1
        if not installer.download_version(args.version):
            return 1
    elif args.action == 'install':
        success = False
        if args.version:
            # Download specific version then install
            if installer.download_version(args.version):
                if installer.use_version(args.version):
                    success = installer._install_system_wide(args.version, args.force)
        else:
            success = installer.install_latest(args.force)
        if not success:
            return 1
    elif args.action == 'use':
        if not args.version:
            installer.print_error("Version required for use")
            return 1
        if not installer.use_version(args.version):
            return 1
    elif args.action == 'remove':
        if not args.version:
            installer.print_error("Version required for remove")
            return 1
        if not installer.remove_version(args.version):
            return 1
    elif args.action == 'active':
        active = installer.get_active_version()
        if active:
            installer.print_success(f"Active version: {active}")
        else:
            installer.print_info("No active version set")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
PYTHON_SCRIPT_EOF

    echo "$temp_script"
}

# Main installation function
run_installation() {
    print_step "Starting Cursor IDE installation..."
    
    # Create the embedded Python installer
    PYTHON_INSTALLER=$(create_python_installer)
    
    # Ask what the user wants to do
    echo
    print_info "What would you like to do?"
    echo "  1) Install latest version (recommended)"
    echo "  2) List available versions"
    echo "  3) List available versions (force refresh)"
    echo "  4) Install specific version"
    echo "  5) Remove specific version"
    echo "  6) Exit"
    echo
    
    read -p "Enter your choice [1-6]: " choice
    
    installed=false
    
    case "$choice" in
        1)
            print_step "Installing latest Cursor IDE version..."
            if python3 "$PYTHON_INSTALLER" install; then
                installed=true
            fi
            ;;
        2)
            print_step "Listing available versions..."
            python3 "$PYTHON_INSTALLER" list
            echo
            if ask_permission "Would you like to install the latest version now?"; then
                print_step "Installing latest Cursor IDE version..."
                if python3 "$PYTHON_INSTALLER" install; then
                    installed=true
                fi
            fi
            ;;
        3)
            print_step "Listing available versions (forcing refresh)..."
            # Clear cache first
            rm -f ~/.local/share/cursor-installer/versions_cache.json 2>/dev/null || true
            python3 "$PYTHON_INSTALLER" list
            echo
            if ask_permission "Would you like to install the latest version now?"; then
                print_step "Installing latest Cursor IDE version..."
                if python3 "$PYTHON_INSTALLER" install; then
                    installed=true
                fi
            fi
            ;;
        4)
            python3 "$PYTHON_INSTALLER" list
            echo
            read -p "Enter version to install (e.g., 1.3.4): " version
            if [[ -n "$version" ]]; then
                print_step "Installing Cursor v$version..."
                if python3 "$PYTHON_INSTALLER" install "$version"; then
                    installed=true
                fi
            else
                print_error "No version specified"
            fi
            ;;
        5)
            python3 "$PYTHON_INSTALLER" list
            echo
            read -p "Enter version to remove (e.g., 1.3.4): " version
            if [[ -n "$version" ]]; then
                print_step "Removing Cursor v$version..."
                python3 "$PYTHON_INSTALLER" remove "$version"
            else
                print_error "No version specified"
            fi
            ;;
        6)
            print_info "Cancelled by user"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    # Cleanup
    rm -f "$PYTHON_INSTALLER"
    
    debug_log "run_installation function completed successfully"
    
    if [[ "$installed" == "true" ]]; then
        show_post_install_info
    fi
}

# Post-installation information
show_post_install_info() {
    print_header
    print_success "Installation completed!"
    echo
    print_info "Cursor IDE has been installed. You can now:"
    echo "  • Launch from Applications menu (search for 'Cursor' in the menu)"
    echo "  • Run 'cursor' from terminal"
    echo "  • Use '/opt/cursor.appimage' directly"
    echo
    if [[ -f "$SYSTEM_SCRIPT_PATH" ]]; then
        print_info "Version management commands available:"
        echo "  • Run 'cursor-update' for interactive management"
        echo "  • The script will auto-check for updates when you run it"
        echo "  • Automatic Cursor close/reopen during updates"
    else
        print_info "For version management, you can install the script system-wide:"
        echo "  curl -fsSL https://raw.githubusercontent.com/jwillians/cursor-update/main/cursor-update.sh | bash"
    fi
    echo
    print_info "If the icon doesn't appear in the menu, try logging out and logging back in, or run 'update-desktop-database /usr/share/applications/'"
    echo
    print_info "Report issues at: https://github.com/jwillians/cursor-update"
    echo
    echo -e "${BOLD}${YELLOW}⚠️  IMPORTANT DISCLAIMER:${NC}"
    echo -e "${YELLOW}   This is an UNOFFICIAL installer created by a fan community member.${NC}"
    echo -e "${YELLOW}   NOT affiliated with, endorsed by, or supported by Anysphere.${NC}"
    echo -e "${YELLOW}   For official support, visit https://www.cursor.com${NC}"
    echo
    print_info "If you encounter namespace or sandbox errors when running the AppImage, try:"
    echo "  sysctl -w user.unprivileged_userns_clone=1"
    echo "  or extract the AppImage with: /opt/cursor.appimage --appimage-extract"
    echo "  and run from the extracted directory."
}

# Trap for cleanup
cleanup() {
    local temp_script="/tmp/cursor_installer_$$.py"
    [[ -f "$temp_script" ]] && rm -f "$temp_script"
}
trap cleanup EXIT INT TERM

# Main execution
main() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. This is not recommended for the entire installation."
        if ! ask_permission "Continue anyway?"; then
            print_info "Installation cancelled"
            exit 0
        fi
    fi
    
    # Show header
    print_header
    
    # Check for script updates (non-blocking)
    if ! check_script_update 2>/dev/null; then
        debug_log "Script update check completed or skipped"
    fi
    echo
    
    # Check for Cursor updates if already installed
    current_cursor_version=$(get_current_cursor_version)
    if [[ -n "$current_cursor_version" ]]; then
        if check_cursor_update "$current_cursor_version" 2>/dev/null; then
            # Update was successful, but still install command if needed
            debug_log "Cursor update completed successfully - checking for command installation"
            
            # Install script to system if not already installed
            if [[ ! -f "$SYSTEM_SCRIPT_PATH" ]]; then
                print_info "🔧 Installing cursor-update command..."
                if install_script_to_system; then
                    print_success "cursor-update command installed successfully!"
                fi
            fi
            
            print_success "All done! Enjoy using Cursor IDE! 🎉"
            echo
            echo -e "${BOLD}${YELLOW}📝 Remember: This is an UNOFFICIAL community tool${NC}"
            echo -e "${YELLOW}   For official support, visit https://www.cursor.com${NC}"
            echo -e "${YELLOW}   Licensed under MIT - see LICENSE file for details${NC}"
            exit 0
        else
            debug_log "Cursor update check completed or skipped - continuing to menu"
            
            # Cursor is already installed and up-to-date, offer menu access
            print_success "Cursor IDE is already at the latest version (v$current_cursor_version)! 🎉"
            print_info "You can use the version management menu to:"
            echo "  • List all available versions"
            echo "  • Install/switch to specific versions"
            echo "  • Remove old versions"
            echo
            
            if ! ask_permission "Open version management menu?"; then
                print_info "Exiting - Cursor is already up-to-date"
                exit 0
            fi
        fi
        echo
    else
        # No Cursor installation detected - show installation message
        print_info "This installer will download and install Cursor IDE on your Linux system."
        print_info "It includes advanced version management and system integration."
        echo
        
        if ! ask_permission "Continue with installation?"; then
            print_info "Installation cancelled by user"
            exit 0
        fi
    fi
    echo
    
    # Check and request sudo access early
    print_step "Checking sudo access..."
    if ! sudo -n true 2>/dev/null; then
        print_info "This installer requires sudo access for system-wide installation."
        print_info "You will be prompted for your password to proceed."
        echo
        if ! sudo -v; then
            print_error "Sudo access is required for installation. Exiting."
            exit 1
        fi
        print_success "Sudo access confirmed"
    else
        print_success "Sudo access already available"
    fi
    echo
    
    # Install script to system early (if not already installed)
    if [[ ! -f "$SYSTEM_SCRIPT_PATH" ]]; then
        print_info "🔧 Installing cursor-update command..."
        if install_script_to_system; then
            print_success "cursor-update command installed successfully!"
            print_info "You can now run: cursor-update"
            echo
        fi
    fi
    
    # Run installation steps
    print_info "🔍 Step 1/5: Detecting system..."
    detect_system
    
    print_info "📦 Step 2/5: Checking dependencies..."
    check_dependencies
    
    print_info "🔍 Step 3/5: Checking existing installations..."
    if ! check_existing_installations; then
        print_warning "There were some issues checking existing installations, but continuing..."
        debug_log "check_existing_installations failed but continuing"
    fi
    
    print_info "🔧 Step 4/5: Checking AppImage compatibility..."
    if ! check_libfuse2; then
        print_warning "There were some issues checking AppImage compatibility, but continuing..."
        debug_log "check_libfuse2 failed but continuing"
    fi
    
    print_info "🧹 Final cleanup: Ensuring old desktop entries are removed..."
    # Skip cleanup during updates to avoid removing fresh desktop entries
    current_cursor_version=$(get_current_cursor_version)
    if [[ -z "$current_cursor_version" ]]; then
        # Only clean up if this is a fresh installation, not an update
        cleanup_old_desktop_entries
    else
        print_info "Skipping desktop cleanup during update to preserve fresh entries"
    fi
    
    print_info "🚀 Step 5/6: Running installation..."
    run_installation
    
    # Script installation was already handled earlier
    echo
    
    print_success "All done! Enjoy using Cursor IDE! 🎉"
    echo
    echo -e "${BOLD}${YELLOW}📝 Remember: This is an UNOFFICIAL community tool${NC}"
    echo -e "${YELLOW}   For official support, visit https://www.cursor.com${NC}"
    echo -e "${YELLOW}   Licensed under MIT - see LICENSE file for details${NC}"
}

# Execute main function
main "$@"
