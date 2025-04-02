# nazDots

My personal dotfiles managed with GNU Stow.

## Prerequisites

- GNU Stow
- Bash
- Git

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/nazDots.git
cd nazDots
```

2. Use stow to symlink configurations:
```bash
stow <package_name>
```

For example, to install neovim configuration:
```bash
stow nvim
```

## Managing Configurations

### Adding New Configurations

This repository includes a helper script `create_stow_package.sh` that simplifies the process of creating new stow packages from existing configuration directories.

#### Usage

```bash
./create_stow_package.sh [-v] [-n] <pkgname> <config_dir>
```

Options:
- `-v`: Verbose mode (shows additional debug information)
- `-n`: Dry-run mode (shows commands without executing them)

Arguments:
- `pkgname`: Name of the stow package to create
- `config_dir`: Path to the existing configuration directory

Example:
```bash
# Create a stow package for neovim configuration
./create_stow_package.sh nvim ~/.config/nvim

# Dry-run to see what would happen
./create_stow_package.sh -n zsh ~/.config/zsh

# Verbose mode for detailed information
./create_stow_package.sh -v tmux ~/.config/tmux
```

The script will:
1. Create a backup of your existing configuration
2. Create the necessary directory structure
3. Move your configuration to the appropriate location in the stow package

### Package Structure

Each stow package maintains the same directory structure as it would appear in your home directory. For example:
```
nazDots/
├── nvim/
│ └── .config/
│ └── nvim/
│ └── init.lua
├── zsh/
│ └── .config/
│ └── zsh/
│ └── .zshrc
└── create_stow_package.sh
```

## Removing Configurations

To remove symlinks created by stow:

```bash
stow -D <package_name>
```

## Restowing Configurations

If you've made changes to the package structure and need to update symlinks:

```bash
stow -R <package_name>
```

## Safety Features

- The `create_stow_package.sh` script creates automatic backups before moving configurations
- Dry-run mode (`-n`) allows you to preview changes before executing them
- Confirmation prompts prevent accidental operations
- Input validation ensures package names are valid

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0) - see the [LICENSE](LICENSE) file for details.