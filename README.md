# Cursor IDE Installer for Ubuntu

🚀 **One-command installation!**

Professional standalone installer for Cursor IDE on Ubuntu systems with automatic dependency management, version control, and complete system integration.

## 📋 Correções Implementadas

**Status do projeto:** Todas as correções implementadas! 🎉

### Correções realizadas:

- [x] **1. Verificação de versões antigas**: Se não existir versões antigas do Cursor instaladas, o script não deve sugerir a desinstalação de versões antigas (atualmente sempre sugere) ✅

- [x] **2. Solicitação antecipada do sudo**: O script deve solicitar privilégios sudo no começo da execução, pois é necessário para remover instalações existentes e instalar no sistema ✅

- [x] **3. Atualização da lista de versões**: O script precisa buscar e exibir as versões mais atuais disponíveis (atualmente mostra 1.3.4 como mais recente, mas já existe 1.3.6+) ✅

- [x] **4. Integração completa com desktop**: 
  - [x] Criar atalho funcional na dock/menu do Ubuntu ✅
  - [x] Extrair e usar o ícone do próprio AppImage ao invés de baixar da web ✅
  - [x] Garantir que o aplicativo apareça corretamente no menu de aplicativos ✅
  - [x] Configurar associações de arquivo adequadas ✅

### Resumo das melhorias implementadas:
- 🟢 **Todas as 4 correções concluídas** - Implementadas e testadas
- 🎯 **Detecção inteligente** - Não sugere remoção se não há versões antigas
- 🔐 **Sudo antecipado** - Solicita privilégios no início do processo  
- 🔄 **Descoberta automática** - Busca versões mais recentes automaticamente
- 🖥️ **Integração completa** - Ícone do AppImage, atalhos, associações de arquivo

### Bugs corrigidos na v2.1:
- 🔧 **Sudo duplo** - Corrigido para não solicitar sudo duas vezes
- 🔍 **Probing de versões** - Melhorado para encontrar versões mais recentes (testa múltiplos padrões de URL)
- 🖥️ **Integração desktop robusta** - Debugging e validação melhorados para garantir criação de atalhos

### Hotfixes v2.1.1:
- 💾 **Cache inteligente** - Força renovação automática se cache contém apenas versões antigas (< 1.3.5)
- 🔄 **Opção force refresh** - Nova opção no menu para forçar busca de versões mais recentes
- 🖥️ **Desktop debugging** - Verificação detalhada de criação e persistência de atalhos
- 📊 **Probing verboso** - Debugging detalhado do processo de descoberta de versões

### Major Update v2.2.0:
- 🚀 **Descoberta 100% dinâmica** - Sempre consulta as últimas 10 versões disponíveis
- ❌ **Fallback removido** - Elimina completamente versões hardcoded desatualizadas
- 🔮 **Preparado para o futuro** - Suporte automático para versões 1.4.x, 1.5.x, 2.x, etc.
- ⚡ **Performance otimizada** - Timeouts reduzidos, cache de 6 horas, descoberta mais rápida
- 🎯 **Top 10 garantido** - Sempre retorna as 10 versões mais recentes encontradas

### Bugfix v2.2.1:
- 🛠️ **Descoberta dinâmica simplificada** - Corrige problemas de descoberta e download de versões
- 🐛 **Proteção de debug** - Exclui `/home/jwillians/Downloads/Cursor-1.3.6-x86_64.AppImage` da remoção
- 🔒 **Processo debug protegido** - Não fecha processos da versão de debug durante limpeza
- 🆘 **Fallback de emergência** - Se descoberta falhar, oferece versões 1.3.6, 1.3.5, 1.3.4
- 🔧 **URLs corrigidas** - Corrige URLs de ícones e melhora robustez

---

## 🚀 Quick Installation

### One-Command Install (Recommended)
```bash
# Install with single command
curl -fsSL https://gist.githubusercontent.com/jwillians/GIST_ID/raw/install-cursor.sh | bash
```

### Alternative Methods
```bash
# Download and inspect first (more secure)
wget https://gist.githubusercontent.com/jwillians/GIST_ID/raw/install-cursor.sh
chmod +x install-cursor.sh
./install-cursor.sh

# Or clone this repository
git clone https://github.com/jwillians/cursor-update.git
cd cursor-update
chmod +x install-cursor.sh
./install-cursor.sh
```

## ✨ Features

- 🎯 **One-Command Install**: Simple installation with `curl | bash`
- 🚀 **Dynamic Version Discovery**: Always finds the latest 10 versions automatically
- 🔮 **Future-Proof**: Supports versions 1.4.x, 1.5.x, 2.x and beyond
- 🔍 **Smart Dependencies**: Auto-detects and installs required packages
- 🛡️ **Interactive Permissions**: Asks for confirmation at each step
- 🎨 **Beautiful Interface**: Colorized output with progress indicators
- 🏗️ **System Detection**: Automatically detects Ubuntu/Debian and architecture
- 📦 **Complete Integration**: Desktop shortcuts, shell commands, everything
- 🔄 **Version Management**: Download and switch between versions
- 🧹 **Self-Contained**: No external files needed, everything embedded

## 📋 What It Does

### Automatic System Detection
- ✅ Detects Ubuntu/Debian distribution and version
- ✅ Identifies architecture (x64/ARM64)
- ✅ Checks for Ubuntu 24.04+ libfuse2 compatibility

### Smart Dependency Management
- ✅ Auto-installs missing system packages (`curl`, `wget`, `sudo`)
- ✅ Checks and installs Python 3.8+ if needed
- ✅ Installs required Python packages automatically
- ✅ Handles `libfuse2` for AppImage support

### Interactive Installation Process
1. **System Check**: Verifies compatibility and dependencies
2. **Permission Requests**: Asks before installing anything
3. **Version Selection**: Choose latest, browse versions, or pick specific version
4. **Download & Install**: Progress tracking with retry logic
5. **System Integration**: Desktop shortcuts, shell commands, menu integration

### Dynamic Version Discovery (v2.2.0+)
- 🚀 **Real-time Discovery**: Tests Cursor's servers for the latest versions
- 🔢 **Top 10 Versions**: Always shows the 10 most recent available versions  
- 🔮 **Future-Ready**: Automatically detects 1.4.x, 1.5.x, 2.x series when released
- ⚡ **Smart Caching**: 6-hour cache with intelligent refresh triggers
- 🌐 **Multiple URL Patterns**: Tests 3 different download URL structures
- ❌ **No Hardcoded Versions**: Completely eliminates outdated fallback lists

### Complete Integration
- 🖥️ **Desktop Integration**: Application menu entry with extracted AppImage icon
- 💻 **Shell Command**: `cursor` command available system-wide
- 📂 **File Association**: Opens code files and directories
- 🔧 **Version Management**: Switch between downloaded versions
- 💾 **Auto Backup**: Backs up existing installations

## Requirements

- Ubuntu 18.04+ (other Debian-based distributions may work)
- Architecture: x86_64 (x64) or ARM64
- Internet connection for downloads
- `sudo` access for system-wide installation

*Note: Python 3.8+ and other dependencies are auto-installed if missing*

## Usage

### Interactive Installation
```bash
# Run the installer
./install-cursor.sh

# Follow the interactive prompts:
# 1) Install latest version (recommended)  ← Choose this
# 2) List available versions
# 3) Install specific version
# 4) Exit
```

### Example Installation Flow
```
🎯 Cursor IDE Installer v2.0.0
   Professional Ubuntu Installer & Version Manager
================================================================

ℹ This installer will download and install Cursor IDE on your Ubuntu system.
ℹ It includes advanced version management and system integration.

❓ Continue with installation? [Y/n] y

▶ Detecting system information...
ℹ System: ubuntu 22.04
ℹ Architecture: x86_64 (x64)

▶ Checking system dependencies...
✓ All system dependencies found
✓ Python 3.10 found
✓ All Python dependencies ready

▶ Starting Cursor IDE installation...
ℹ What would you like to do?
  1) Install latest version (recommended)
  2) List available versions  
  3) Install specific version
  4) Exit

Enter your choice [1-4]: 1

▶ Installing latest Cursor IDE version...
ℹ Downloading Cursor v1.3.4...
ℹ Progress: 100.0% (142.5 MB downloaded)
✓ Downloaded Cursor v1.3.4
✓ Switched to Cursor v1.3.4
✓ Cursor v1.3.4 installed successfully!

ℹ You can now launch Cursor from:
  • Applications menu
  • Terminal: cursor
  • Direct: /opt/cursor.appimage
```

## File Locations After Installation

```
System Files:
├── /opt/cursor.appimage              # Main executable
├── /usr/share/applications/cursor.desktop  # Desktop entry
├── /usr/share/pixmaps/cursor.png     # Application icon
└── /usr/local/bin/cursor             # Shell command

User Files:
├── ~/.local/share/cursor-installer/   # Version management
│   ├── versions/                     # Downloaded versions
│   ├── active -> versions/cursor-X.X.X.AppImage  # Active symlink
│   └── versions_cache.json          # Version cache
├── ~/.cursor/                        # User configurations
└── ~/Applications/cursor/backups/    # Automatic backups
```

## Troubleshooting

### Common Issues

**Q: Permission denied errors**
```bash
# Make sure you have sudo access
sudo -v
```

**Q: Script fails to download**
```bash
# Check internet connection
ping -c 3 github.com

# Try manual download
wget https://gist.githubusercontent.com/jwillians/GIST_ID/raw/install-cursor.sh
```

**Q: Python dependencies fail**
```bash
# Update package list
sudo apt update

# Install Python manually if needed
sudo apt install python3 python3-pip
```

**Q: AppImage won't run on Ubuntu 24.04+**
```bash
# The installer handles this automatically
# It will either install libfuse2 or use extraction method
```

### Manual Recovery
If something goes wrong, you can manually clean up:

```bash
# Remove system files
sudo rm -f /opt/cursor.appimage
sudo rm -f /usr/share/applications/cursor.desktop
sudo rm -f /usr/share/pixmaps/cursor.png
sudo rm -f /usr/local/bin/cursor

# Remove user files (optional)
rm -rf ~/.local/share/cursor-installer/
rm -rf ~/Applications/cursor/backups/
# Keep ~/.cursor/ if you want to preserve settings
```

## Ubuntu 24.04 Compatibility

Ubuntu 24.04+ may have AppImage issues due to libfuse2 deprecation. The installer automatically handles this by:

1. **Auto libfuse2 Installation**: Prompts to install when needed
2. **AppImage Extraction**: Extract and run natively as fallback
3. **Smart Detection**: Recognizes Ubuntu 24.04+ and adapts accordingly

## Security Notes

- **Open Source**: All code is visible and auditable
- **Interactive**: Asks permission before installing anything
- **No Auto-Execution**: Downloads files but asks before running them
- **Backup First**: Creates backups before overwriting existing installations
- **Standard Locations**: Uses conventional Linux file locations

## Publishing to GitHub Gist

To make your installer available via `curl`:

1. **Create Gist**: Go to [gist.github.com](https://gist.github.com)
2. **Upload Script**: Paste the content of `install-cursor.sh`
3. **Set Public**: Make sure it's marked as public
4. **Get Raw URL**: Copy the raw URL from the gist
5. **Share**: Your users can then run:
   ```bash
   curl -fsSL https://gist.githubusercontent.com/USERNAME/GIST_ID/raw/install-cursor.sh | bash
   ```

## Support

For issues and feature requests:
1. **Repository Issues**: [https://github.com/jwillians/cursor-update/issues](https://github.com/jwillians/cursor-update/issues)
2. **Check Documentation**: Review this README and troubleshooting section
3. **Verify Latest**: Make sure you're using the newest version

## License

This project is open source. Check the repository for license details.

---

**🎉 Install Cursor IDE with ease!**

Repository: [https://github.com/jwillians/cursor-update](https://github.com/jwillians/cursor-update) 