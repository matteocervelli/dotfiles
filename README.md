# Dotfiles

Personal dotfiles and development environment configuration for macOS.

## 🚀 Features

- ✅ ZSH configuration with custom aliases and functions
- ✅ Git configuration and aliases
- ✅ Development tools setup
- 🚧 IDE configurations (in progress)

## 🛠️ Tech Stack

- [ZSH](https://www.zsh.org/) - Shell
- [Git](https://git-scm.com/) - Version control
- [Homebrew](https://brew.sh/) - Package manager

## 📦 Installation

```bash
git clone https://github.com/matteocervelli/dotfiles.git
cd dotfiles
./install.sh
```

## 🧪 Usage

```bash
# Source the configurations
source ~/.zshrc
```

### Key Commands

After running `make stow` (or `stow bin/`), these commands become available:

**Asset Management** (Issue #29-#31):
- `update-cdn` - Update central library manifest, propagate to projects, sync to R2
- `sync-project` - Sync project assets with library-first strategy
- `cdnsync` - Sync central library to R2 (alias for rclone-cdn-sync)

**R2 Configuration**:
- `setup-rclone` - Configure rclone for Cloudflare R2
- `test-rclone` - Test R2 connection

See [sync/manifests/README.md](sync/manifests/README.md) for complete asset management documentation.

## 📁 Project Structure

```text
config/     # Configuration files
scripts/    # Installation and utility scripts
docs/       # Documentation
dotfiles/   # Actual dotfiles (.zshrc, .gitconfig, etc.)
```

## 🤝 Contributing

Contributions are welcome! Please open an issue or pull request.

## 📄 License

Distributed under the MIT License. See LICENSE for more information.
