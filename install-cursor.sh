#!/bin/bash
#
# Cursor IDE Installer - Standalone Script
# Professional installer for Ubuntu systems
# 
# Install with: curl -fsSL https://your-domain.com/install-cursor.sh | bash
# Or download and run: bash install-cursor.sh
#
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
INSTALLER_VERSION="2.2.1"
SCRIPT_NAME="Cursor IDE Installer"

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
    echo -e "${BOLD}${CYAN}    Professional Ubuntu Installer & Version Manager${NC}"
    echo -e "${BOLD}${CYAN}================================================================${NC}"
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
        print_warning "This installer is designed for Ubuntu/Debian systems"
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

# Check for existing Cursor installations
check_existing_installations() {
    print_step "Checking for existing Cursor installations..."
    
    local existing_installations=()
    local running_processes=()
    
    # Check for running Cursor processes (more specific detection)
    # Look for actual Cursor IDE processes, not just any process with "cursor" in name
    # Exclude debug version at /home/jwillians/Downloads/Cursor-1.3.6-x86_64.AppImage
    local cursor_processes=$(ps aux | grep -E '(/cursor\.appimage|/Cursor.*\.AppImage|cursor --no-sandbox)' | grep -v grep | grep -v "install-cursor.sh" | grep -v "/home/jwillians/Downloads/Cursor-1.3.6-x86_64.AppImage")
    local cursor_check=$(echo "$cursor_processes" | wc -l)
    if [[ "$cursor_check" -gt 0 && -n "$(echo "$cursor_processes" | tr -d '[:space:]')" ]]; then
        local cursor_pids=$(echo "$cursor_processes" | awk '{print $2}' | tr '\n' ' ')
        running_processes+=("Running Cursor IDE processes found (PIDs: $cursor_pids)")
        print_info "🐛 DEBUG: Excluding debug version /home/jwillians/Downloads/Cursor-1.3.6-x86_64.AppImage from process detection"
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
        if [[ "$installation" != *"cursor-installer/versions"* ]] && [[ "$installation" != "/opt/cursor.appimage" ]] && [[ "$installation" != *"/tmp/.mount_cursor"* ]] && [[ "$installation" != *"/home/jwillians/Downloads/Cursor-1.3.6-x86_64.AppImage"* ]]; then
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
        elif [[ "$installation" == *"/home/jwillians/Downloads/Cursor-1.3.6-x86_64.AppImage"* ]]; then
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
        
        if ask_permission "Stop all Cursor processes before installation?"; then
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
                local remaining_cursor_processes=$(ps aux | grep -E '(/cursor\.appimage|/Cursor.*\.AppImage|cursor --no-sandbox)' | grep -v grep | grep -v "install-cursor.sh" | grep -v "/home/jwillians/Downloads/Cursor-1.3.6-x86_64.AppImage")
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
                local final_cursor_processes=$(ps aux | grep -E '(/cursor\.appimage|/Cursor.*\.AppImage|cursor --no-sandbox)' | grep -v grep | grep -v "install-cursor.sh" | grep -v "/home/jwillians/Downloads/Cursor-1.3.6-x86_64.AppImage")
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
            sudo rm -f /usr/share/applications/*cursor*.desktop 2>/dev/null || true
            sudo rm -f /usr/local/bin/cursor 2>/dev/null || true
            sudo rm -f /usr/bin/cursor 2>/dev/null || true
            
            print_success "Existing installations cleaned up"
        else
            print_warning "Existing installations will remain"
            print_info "This may cause conflicts or confusion about which version is active"
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
            'User-Agent': 'Cursor-Installer/2.2.1 (Ubuntu)'
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

    def discover_versions_by_probing(self) -> List[Dict[str, str]]:
        """Discover available versions by probing Cursor's download URLs dynamically."""
        arch = self.detect_architecture()
        arch_path = 'x64' if arch == 'x64' else 'arm64'
        arch_suffix = 'x86_64' if arch == 'x64' else 'arm64'
        
        discovered_versions = []
        
        self.print_info("🔍 Dynamic version discovery - testing for latest 10+ versions")
        self.print_info(f"Architecture: {arch} ({arch_path}, {arch_suffix})")
        
        # URL patterns to test (in order of preference)
        url_patterns = [
            f"https://downloads.cursor.com/production/latest/linux/{arch_path}/Cursor-{{version}}-{arch_suffix}.AppImage",
            f"https://downloads.cursor.com/production/{{version}}/linux/{arch_path}/Cursor-{{version}}-{arch_suffix}.AppImage", 
            f"https://downloads.cursor.com/linux/{arch_path}/Cursor-{{version}}-{arch_suffix}.AppImage"
        ]
        
        # Version series to test (from newest to oldest)
        version_series = [
            # Start with current known versions and probe higher
            {"major": 1, "minor": 4, "patch_range": range(0, 15)}, # 1.4.0 - 1.4.14
            {"major": 1, "minor": 3, "patch_range": range(4, 25)}, # 1.3.4 - 1.3.24
            {"major": 1, "minor": 2, "patch_range": range(0, 10)}, # 1.2.0 - 1.2.9
            {"major": 1, "minor": 1, "patch_range": range(0, 10)}, # 1.1.0 - 1.1.9
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
        """Test if a specific version exists using any of the URL patterns."""
        for pattern in url_patterns:
            test_url = pattern.format(version=version)
            try:
                response = self.session.head(test_url, timeout=4)  # Faster timeout
                if response.status_code in [200, 301, 302, 403]:  # Consider redirects and auth as valid
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
                if response.status_code in [200, 301, 302, 403]:
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
        
        # Emergency fallback to most likely current versions
        arch = self.detect_architecture()
        arch_path = 'x64' if arch == 'x64' else 'arm64'
        arch_suffix = 'x86_64' if arch == 'x64' else 'arm64'
        
        emergency_versions = [
            ("1.3.6", f"https://downloads.cursor.com/production/latest/linux/{arch_path}/Cursor-1.3.6-{arch_suffix}.AppImage"),
            ("1.3.5", f"https://downloads.cursor.com/production/latest/linux/{arch_path}/Cursor-1.3.5-{arch_suffix}.AppImage"),
            ("1.3.4", f"https://downloads.cursor.com/production/bfb7c44bcb74430be0a6dd5edf885489879f2a2e/linux/{arch_path}/Cursor-1.3.4-{arch_suffix}.AppImage"),
        ]
        
        fallback_list = []
        for ver, url in emergency_versions:
            fallback_list.append({
                'version': ver,
                'tag_name': f"v{ver}",
                'published_at': 'Emergency',
                'download_url': url
            })
        
        self.print_info(f"Using emergency fallback with {len(fallback_list)} versions")
        return fallback_list

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
            # Improved regex to handle Cursor/cursor, version, optional arch suffix
            match = re.search(r'[Cc]ursor-([^.]+(?:\.[^.]+)*?)(?:-[a-z0-9_]+)?\.AppImage$', file_path.name, re.IGNORECASE)
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
            match = re.search(r'[Cc]ursor-([^.]+(?:\.[^.]+)*?)(?:-[a-z0-9_]+)?\.AppImage$', target_path.name, re.IGNORECASE)
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
            match = re.search(r'[Cc]ursor-([^.]+(?:\.[^.]+)*?)(?:-[a-z0-9_]+)?\.AppImage$', file.name, re.IGNORECASE)
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
            match = re.search(r'[Cc]ursor-([^.]+(?:\.[^.]+)*?)(?:-[a-z0-9_]+)?\.AppImage$', file.name, re.IGNORECASE)
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
            match = re.search(r'[Cc]ursor-([^.]+(?:\.[^.]+)*?)(?:-[a-z0-9_]+)?\.AppImage$', file.name, re.IGNORECASE)
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

    def _create_desktop_integration(self):
        """Create enhanced desktop shortcut with proper icon extraction."""
        self.print_info("Creating desktop integration...")
        
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
    print_info "If the icon doesn't appear in the menu, try logging out and logging back in, or run 'update-desktop-database /usr/share/applications/'"
    echo
    print_info "For version management, download this script and run:"
    echo "  bash install-cursor.sh"
    echo
    print_info "Report issues at: https://github.com/your-repo/cursor-installer"
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
    
    # Welcome message
    print_info "This installer will download and install Cursor IDE on your Ubuntu system."
    print_info "It includes advanced version management and system integration."
    echo
    
    if ! ask_permission "Continue with installation?"; then
        print_info "Installation cancelled by user"
        exit 0
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
    
    print_info "🚀 Step 5/5: Running installation..."
    run_installation
    
    print_success "All done! Enjoy using Cursor IDE! 🎉"
}

# Execute main function
main "$@"
