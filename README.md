# 🎯 Cursor Update v1.1.3

> **Unofficial Linux Installer & Version Manager for Cursor IDE**

⚠️ **DISCLAIMER: This is an UNOFFICIAL installer created by a fan (Jorge Willians).**  
**NOT affiliated with, endorsed by, or officially supported by Anysphere (the creators of Cursor IDE).**  
**Use at your own risk. Cursor IDE is a trademark of Anysphere.**  
**For official support, visit [cursor.com](https://www.cursor.com)**

A comprehensive, standalone script that downloads, installs, and manages Cursor IDE versions on Linux systems with advanced features like version management, desktop integration, and AI-powered development environment setup.

## ✨ Features

### 🚀 **Smart Installation**
- **Latest Version Detection**: Automatically fetches the most recent Cursor IDE version using official APIs
- **Multiple Architecture Support**: x64 and ARM64 compatible
- **Dependency Management**: Automatically installs required system dependencies
- **AppImage Integration**: Full AppImage support with libfuse2 handling
- **System Integration**: Installs script as `cursor-update` command system-wide

### 🔧 **Advanced Version Management**
- **Download Multiple Versions**: Keep different Cursor versions locally
- **Switch Between Versions**: Easily change active Cursor version
- **Version Caching**: Smart caching system for faster operations
- **Backup System**: Automatic backup of previous installations
- **Auto-Update Detection**: Automatically checks for Cursor and script updates
- **Smart Update Process**: Closes Cursor, updates, and reopens automatically

### 🖥️ **Desktop Integration**
- **Application Menu Entry**: Creates proper desktop shortcuts
- **Icon Extraction**: Automatically extracts and installs Cursor icons
- **MIME Type Support**: Associates code files with Cursor
- **Shell Integration**: Adds `cursor` command to terminal

### 🛡️ **Safety Features**
- **Process Protection**: Protects running Cursor instances during installation
- **Conflict Detection**: Identifies and manages existing installations
- **Rollback Support**: Backup and restore capabilities
- **Debug Mode**: Comprehensive logging for troubleshooting
- **Current Version Display**: Shows installed Cursor version on script startup
- **Self-Update Capability**: Script can update itself to latest version

## 📋 Requirements

### System Requirements
- **OS**: Linux distributions (tested on Ubuntu/Debian)
- **Architecture**: x86_64 (x64) or ARM64
- **RAM**: 4GB minimum (8GB+ recommended)
- **Disk Space**: ~2GB for installation and cache
- **Network**: Internet connection required

### Dependencies (Auto-installed)
- `curl` - For downloads
- `wget` - Backup downloader
- `python3` (3.8+) - Core installer logic
- `libfuse2` - AppImage support
- Python packages: `requests`, `beautifulsoup4`, `lxml`, `packaging`

## 🚀 Quick Start

### 🚀 One-Line Installation (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/jwillians/cursor-update/main/cursor-update.sh | bash
```

> **💡 Tip:** This is the fastest and safest method - similar to `curl -fsSL https://ollama.com/install.sh | sh`

### Manual Installation
```bash
# Download the script
wget https://raw.githubusercontent.com/jwillians/cursor-update/main/cursor-update.sh

# Make it executable
chmod +x cursor-update.sh

# Run the installer
./cursor-update.sh
```

## 🔗 How Curl Installation Works

### 🌐 Direct GitHub URL
Yes! You can use curl directly from a GitHub URL without any problems:

```bash
# Standard method (recommended)
curl -fsSL https://raw.githubusercontent.com/jwillians/cursor-update/main/cursor-update.sh | bash

# Or specific version using tags
curl -fsSL https://raw.githubusercontent.com/jwillians/cursor-update/v1.0.0/cursor-update.sh | bash
```

### 🔐 Installation Security

```bash
# For enhanced security, you can:
# 1. First download and review the script
curl -fsSL https://raw.githubusercontent.com/jwillians/cursor-update/main/cursor-update.sh -o cursor-update.sh

# 2. Verify the content
cat cursor-update.sh | head -50

# 3. Execute only if you trust it
bash cursor-update.sh
```

## 📖 Usage

### Interactive Mode
Simply run the script and follow the interactive prompts:
```bash
./cursor-update.sh
# Or if installed system-wide:
cursor-update
```

**Available options:**
1. **Install latest version** (recommended)
2. **List available versions**
3. **List available versions** (force refresh)
4. **Install specific version**
5. **Remove specific version**
6. **Exit**

### Direct Commands
The script also supports direct version management:

```bash
# Use the interactive menu
./cursor-update.sh  # Local script
# Or: cursor-update  # If installed system-wide

# Available menu options:
# 1. Install latest version
# 2. List available versions  
# 3. List versions (force refresh)
# 4. Install specific version
# 5. Remove specific version
# 6. Exit
```

## 🎮 After Installation

### Launch Cursor IDE
- **Applications Menu**: Search for "Cursor"
- **Terminal**: Type `cursor`
- **Direct**: Run `/opt/cursor.appimage`

### Version Management & Auto-Updates

#### 🚀 Quick Management (System Command)
```bash
# Run the installed system command
cursor-update

# The script will automatically:
# 1. Show current Cursor version
# 2. Check for script updates 
# 3. Check for Cursor updates
# 4. Offer to update with auto-restart
```

#### 🔄 Auto-Update Features
- **Script Self-Update**: Automatically detects and offers to update the script itself
- **Cursor Update Detection**: Shows available Cursor updates on startup
- **Smart Process Management**: Safely closes Cursor, updates, and reopens automatically
- **Version Display**: Always shows your current Cursor version

#### 📋 Manual Version Commands
```bash
# Check active version
cursor --version

# Manual version management
cursor-update  # Interactive mode with all options
```

## 🐛 Troubleshooting

### Common Issues

#### AppImage Won't Run
```bash
# Install libfuse2
sudo apt update
sudo apt install libfuse2

# Or run with extraction
/opt/cursor.appimage --appimage-extract-and-run
```

#### Permission Errors
```bash
# Fix AppImage permissions
sudo chmod +x /opt/cursor.appimage

# Fix executable permissions
chmod +x cursor-update.sh
```

#### Desktop Icon Missing
```bash
# Refresh desktop database
sudo update-desktop-database /usr/share/applications/
# Logout and login again
```

#### Network/Download Issues
```bash
# Run with debug mode
DEBUG=1 ./cursor-update.sh

# Clear cache and retry
rm -rf ~/.local/share/cursor-installer/versions_cache.json
```

### Debug Mode
Enable detailed logging:
```bash
DEBUG=1 ./cursor-update.sh
```

## 🔧 Configuration

### Installation Paths
- **Main Installation**: `/opt/cursor.appimage`
- **Desktop Entry**: `/usr/share/applications/cursor.desktop`
- **Icon**: `/usr/share/pixmaps/cursor.png`
- **Shell Command**: `/usr/local/bin/cursor`
- **Update Script**: `/usr/local/bin/cursor-update`
- **Version Cache**: `~/.local/share/cursor-installer/`

### Customization
The script automatically detects your system and configures appropriately. For custom installations, you can modify variables at the top of the script.

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### 🐛 Bug Reports
- Use the [Issues](https://github.com/jwillians/cursor-update/issues) page
- Include system information (`lsb_release -a`)
- Provide error logs (run with `DEBUG=1`)

### 💡 Feature Requests
- Check existing [Issues](https://github.com/jwillians/cursor-update/issues) first
- Describe the use case and expected behavior
- Consider submitting a Pull Request

### 🔧 Pull Requests
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Test your changes thoroughly
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Cursor Team](https://cursor.com) for creating an amazing AI-powered IDE
- Linux community for the excellent package management systems
- Contributors and users who help improve this installer

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/jwillians/cursor-update/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jwillians/cursor-update/discussions)
- **Documentation**: This README and script comments

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Important Legal Notice

**This is an UNOFFICIAL installer created by a fan (Jorge Willians).**
- **NOT affiliated with, endorsed by, or officially supported by Anysphere**
- **Cursor IDE is a trademark of Anysphere**
- **This installer simply automates the download and installation process using publicly available releases**
- **For official support, visit [cursor.com](https://www.cursor.com)**

---

<div align="center">

**⭐ If this project helped you, please consider giving it a star! ⭐**

Made with ❤️ for the developer community

</div>