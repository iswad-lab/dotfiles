# Dotfiles - Iswad

Reproducible setup for **CachyOS x86_64** + KDE Plasma 6 + NVIDIA RTX 3070 / AMD Vega hybrid.

## Installation

CachyOS + KDE already installed, then run:

```bash
sh -c "$(curl -fsLS https://raw.githubusercontent.com/iswad-lab/dotfiles/main/install.sh)"
```

## Structure

```
dotfiles/
├── install.sh                  # bootstrap (paru + chezmoi + apply)
├── run_once_01-packages.sh     # run once by chezmoi (re-runs on file change)
├── packages.pacman             # official repo packages
└── packages.aur                # AUR packages
```

## Stack

- **Shell**: zsh
- **DE**: KDE Plasma 6 (Wayland)
- **GPU**: NVIDIA RTX 3070 + AMD Vega (hybrid via envycontrol)
- **Audio**: Pipewire + REAPER + yabridge (Windows VST bridge)
- **Virtualization**: QEMU + virt-manager + distrobox
