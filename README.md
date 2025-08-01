# 🎯 Cursor IDE Installer

> **Professional Ubuntu Installer & Version Manager for Cursor IDE**

A comprehensive, standalone script that downloads, installs, and manages Cursor IDE versions on Ubuntu/Debian systems with advanced features like version management, desktop integration, and AI-powered development environment setup.

## ✨ Features

### 🚀 **Smart Installation**
- **Latest Version Detection**: Automatically fetches the most recent Cursor IDE version using official APIs
- **Multiple Architecture Support**: x64 and ARM64 compatible
- **Dependency Management**: Automatically installs required system dependencies
- **AppImage Integration**: Full AppImage support with libfuse2 handling

### 🔧 **Advanced Version Management**
- **Download Multiple Versions**: Keep different Cursor versions locally
- **Switch Between Versions**: Easily change active Cursor version
- **Version Caching**: Smart caching system for faster operations
- **Backup System**: Automatic backup of previous installations

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

## 📋 Requirements

### System Requirements
- **OS**: Ubuntu 18.04+ or Debian-based distributions
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

### One-Line Installation
```bash
curl -fsSL https://raw.githubusercontent.com/jwillians/cursor-update/main/install-cursor.sh | bash
```

### Manual Installation
```bash
# Download the script
wget https://raw.githubusercontent.com/jwillians/cursor-update/main/install-cursor.sh

# Make it executable
chmod +x install-cursor.sh

# Run the installer
./install-cursor.sh
```

## 📖 Usage

### Interactive Mode
Simply run the script and follow the interactive prompts:
```bash
./install-cursor.sh
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
# List available versions
python3 <(curl -s https://raw.githubusercontent.com/jwillians/cursor-update/main/install-cursor.sh | grep -A 1000 "create_python_installer" | grep -B 1000 "echo.*temp_script") list

# Install specific version
./install-cursor.sh  # Choose option 4, then enter version
```

## 🎮 After Installation

### Launch Cursor IDE
- **Applications Menu**: Search for "Cursor"
- **Terminal**: Type `cursor`
- **Direct**: Run `/opt/cursor.appimage`

### Version Management
```bash
# Check active version
cursor --version

# Switch versions (re-run installer and choose option 4)
./install-cursor.sh
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
chmod +x install-cursor.sh
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
DEBUG=1 ./install-cursor.sh

# Clear cache and retry
rm -rf ~/.local/share/cursor-installer/versions_cache.json
```

### Debug Mode
Enable detailed logging:
```bash
DEBUG=1 ./install-cursor.sh
```

## 🔧 Configuration

### Installation Paths
- **Main Installation**: `/opt/cursor.appimage`
- **Desktop Entry**: `/usr/share/applications/cursor.desktop`
- **Icon**: `/usr/share/pixmaps/cursor.png`
- **Shell Command**: `/usr/local/bin/cursor`
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
- Ubuntu/Debian community for the excellent package management system
- Contributors and users who help improve this installer

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/jwillians/cursor-update/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jwillians/cursor-update/discussions)
- **Documentation**: This README and script comments

---

<div align="center">

**⭐ If this project helped you, please consider giving it a star! ⭐**

Made with ❤️ for the developer community

</div>