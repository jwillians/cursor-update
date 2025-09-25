# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.7] - 2025-09-25

### 🐛 Fixed
- **Dynamic Hash Extraction** - Fixed bug where script detected new versions but failed to download due to hardcoded hash URLs
- **API Hash Synchronization** - Script now extracts current hash from API response instead of using outdated hardcoded values
- **Version Download Reliability** - Fixed "Failed to update Cursor" error when newer versions were available but download URLs were invalid

### 🛠️ Technical
- **New `_get_current_hash_from_api()` method** - Dynamically extracts current hash from Cursor API
- **Updated `download_version_direct()`** - Uses dynamic hash for reliable downloads
- **Hash Fallback System** - Maintains compatibility with fallback hash if API extraction fails

## [1.1.6] - 2025-09-22

### 🚀 Added
- **Lightning-Fast API Detection** - Optimized API calls for ~0.2 second version detection
- **Smart Download System** - Skip-discovery flag for faster installations when version is known
- **Future-Proof Versioning** - Added support for versions up to 2.0+ with intelligent fallbacks
- **Direct Download Method** - New `download_version_direct()` bypasses unnecessary version discovery

### ⚡ Performance
- **API Response Time** - Reduced from 30s+ to ~0.2s in optimal cases
- **Download Initialization** - Skip unnecessary version discovery when latest version is known
- **Fallback Efficiency** - Reduced from 300+ version tests to 25 key versions
- **Overall Speed** - Up to 10x faster in common scenarios

### 🛠️ Improved
- **Smart Fallback System** - Tests likely versions first instead of sequential scanning
- **Updated Download URLs** - Fixed direct download URLs for current Cursor releases (hash: b753cece5c67...)
- **Better Timeout Values** - Optimized timeout values for faster failures and recovery
- **Enhanced Error Handling** - More robust API endpoint management with multiple fallbacks

### 🔧 Technical
- **New `--skip-discovery` flag** - Allows bypassing version discovery for known versions
- **Improved URL patterns** - Multiple fallback URL patterns for better compatibility
- **Enhanced version detection** - Better handling of rapid release cycles and version jumps
- **Optimized probing logic** - Smart version testing prioritizes most likely versions

## [1.1.5] - 2025-08-02

### 🐛 Fixed
- **Script update clear screen fix** - Fixed clear command timing with sleep delay to ensure screen is properly cleared after script self-update

## [1.1.4] - 2025-08-02

### 🐛 Fixed
- **Script update visual improvement** - Added clear screen after script self-update to give impression of complete restart
- **Desktop entries preservation** - Fixed unnecessary removal of desktop shortcuts and shell commands when user chooses not to remove existing installations

## [1.1.3] - 2025-08-01

### 🐛 Fixed
- **Fixed stdin availability when script is executed via curl pipe** - Menu now properly waits for user input
- **Improved interactive experience** - All read commands now redirect to /dev/tty for proper input handling
- **Resolved script termination issue** - Script no longer exits after showing menu when piped from curl

### 🧹 Removed
- **Removed obsolete cursor-update-test.sh** - Cleaned up outdated test file to avoid confusion

## [1.1.2] - 2025-08-01

### 🔧 Improved
- **Enhanced sudo logic** - Only requests sudo when actually needed, avoiding unnecessary prompts
- **Conservative update prompts** - Changed default responses to 'n' for safer automatic updates
- **Improved installation checks** - Better validation of existing installations and user prompts

## [1.1.1] - 2025-08-01

### ✨ Added
- **Creator credit attribution** - Added proper attribution to Jorge Willians in disclaimers
- **Enhanced messaging** - Improved user feedback for up-to-date Cursor installations
- **Auto-update mechanism testing** - Version bump to validate auto-update functionality

### 🐛 Fixed
- **Command installation timing** - Fixed issues with cursor-update command installation
- **Desktop integration** - Improved desktop entry cleanup and creation process
- **Debug logging** - Enhanced debug output for better troubleshooting

## [1.0.0] - 2025-07-30

### 🎉 Initial Release

This is the first official release of **Cursor Update** - an unofficial Linux installer and version manager for Cursor IDE.

#### ✨ Added
- **One-line installation** via curl (similar to Ollama's installer)
- **Advanced version management** system with download, switch, and remove capabilities
- **Desktop integration** with automatic icon extraction and menu entries
- **Smart dependency detection** and auto-installation
- **Process protection** to safely handle running Cursor instances
- **AppImage support** with libfuse2 compatibility
- **Backup system** for safe upgrades and rollbacks
- **Interactive CLI** with user-friendly prompts
- **Dynamic version discovery** from Cursor's official APIs
- **Shell integration** with `cursor` command
- **Comprehensive error handling** and debug mode
- **🆕 System script installation** - Installs as `cursor-update` command
- **🆕 Current version display** - Shows installed Cursor version on startup
- **🆕 Auto-update detection** - Checks for script and Cursor updates automatically
- **🆕 Smart update process** - Closes Cursor, updates, and reopens automatically
- **🆕 Self-update capability** - Script can update itself to latest version

#### 🚀 Features
- **Multi-architecture support**: x64 and ARM64
- **Version caching**: Faster operations with smart cache management
- **Conflict detection**: Identifies and manages existing installations
- **MIME type associations**: Automatic file type associations
- **Professional desktop files**: Full desktop environment integration
- **Security features**: Verification and validation of downloads
- **🆕 Intelligent process management**: Safe handling of running Cursor instances
- **🆕 Auto-restart functionality**: Seamless update experience with automatic reopen
- **🆕 Version comparison**: Smart detection of available updates
- **🆕 System-wide availability**: Global `cursor-update` command

#### 📦 Installation Methods
```bash
# One-line installation (recommended)
curl -fsSL https://raw.githubusercontent.com/jwillians/cursor-update/main/cursor-update.sh | bash

# Manual installation
wget https://raw.githubusercontent.com/jwillians/cursor-update/main/cursor-update.sh
chmod +x cursor-update.sh
./cursor-update.sh

# After installation, use system command
cursor-update
```

#### 🎯 Key Highlights
- **Zero configuration required** - works out of the box
- **Intelligent cleanup** - removes old installations and conflicts
- **Professional quality** - enterprise-ready with comprehensive error handling
- **Cross-platform ready** - designed for Ubuntu/Debian systems
- **Developer-friendly** - includes debug mode and verbose logging

#### 🔧 Technical Details
- **User Agent**: `Cursor-Update/1.1.3 (Linux)`
- **Python Requirements**: 3.8+
- **System Requirements**: Ubuntu 18.04+ or Debian-based distributions
- **Dependencies**: Auto-installed (curl, python3, libfuse2, python packages)

### 🙏 Acknowledgments
- Cursor Team for creating an amazing AI-powered IDE
- Ubuntu/Debian community for excellent package management
- All contributors and testers who helped shape this release

---

**Download**: [v1.0.0](https://github.com/jwillians/cursor-update/releases/tag/v1.0.0)
**Full Changelog**: [v1.0.0...main](https://github.com/jwillians/cursor-update/compare/v1.0.0...main)