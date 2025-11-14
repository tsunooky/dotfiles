# Arch Linux Dotfiles

A complete, robust Arch Linux configuration featuring i3wm, polybar, neovim, and custom theming.

## 🚀 Quick Installation

Install everything with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/tsunooky/dotfiles/main/bootstrap.sh | bash
```

## 📦 What's Included

- **Window Manager**: i3-wm with autotiling
- **Status Bar**: Polybar with custom configuration
- **Terminal**: Alacritty
- **Editor**: Neovim with NvChad configuration
- **Audio**: PipeWire with WirePlumber
- **Display Manager**: Ly
- **Theming**: Matugen color generation from wallpapers
- **Development Tools**: GCC, GDB, Clang, Valgrind
- **Applications**: Firefox, Flameshot, Yazi, Zathura

## ✨ Features

- **Robust Installation**: Automatic retry on package failures
- **Error Handling**: Detailed logging and backup system
- **User Configuration**: Interactive DPI and display setup
- **Wallpaper Management**: Automatic color scheme generation
- **Complete Backup**: Automatic backup of existing configurations

## 📋 Requirements

- Fresh Arch Linux installation
- Internet connection
- sudo privileges

## 🛠️ Manual Installation

If you prefer to install manually:

```bash
# Clone the repository
git clone https://github.com/tsunooky/dotfiles.git
cd dotfiles

# Run the installer
chmod +x install.sh
./install.sh
```

## 📁 Directory Structure

```
dotfiles/
├── bootstrap.sh          # Quick installer
├── install.sh           # Main installation script
├── setup.sh            # Legacy setup script
├── config/             # Configuration files
│   └── .config/
│       ├── i3/
│       ├── polybar/
│       ├── alacritty/
│       ├── nvim/
│       └── scripts/
└── install/            # Installation scripts
    ├── pacman.sh
    ├── user-preferences.sh
    ├── yay-install.sh
    ├── nv-chad-install.sh
    └── i3lock-color-install.sh
```

## 🎨 Customization

After installation, run:

```bash
~/.config/scripts/change_wallpaper.sh /path/to/your/wallpaper.jpg
```

This will automatically generate a color scheme and update all themed components.

## 📝 Logs

Installation logs are saved in `/tmp/dotfiles-install/`:
- `install.log` - Full installation log
- `errors.log` - Error messages only
- `failed_packages.txt` - List of packages that failed to install
- `backup/` - Backup of your previous configurations

## 🔧 Troubleshooting

If the installation fails:

1. Check the error log: `cat /tmp/dotfiles-install/errors.log`
2. Review failed packages: `cat /tmp/dotfiles-install/failed_packages.txt`
3. Your previous configs are backed up in `/tmp/dotfiles-install/backup/`

## 📜 License

MIT License - Feel free to use and modify as needed.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

## 👤 Author

**tsunooky**
- GitHub: [@tsunooky](https://github.com/tsunooky)