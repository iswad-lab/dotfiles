# dotfiles — iswad

Config reproductible pour **CachyOS x86_64** + KDE Plasma 6 + NVIDIA RTX 3070 / AMD Vega hybride.

## Installation

CachyOS + KDE déjà installé, puis :

```bash
sh -c "$(curl -fsLS https://raw.githubusercontent.com/iswad/dotfiles/main/install.sh)"
```

## Structure

```
dotfiles/
├── install.sh                  # bootstrap (paru + chezmoi + apply)
├── run_once_01-packages.sh     # installé une fois par chezmoi
├── packages.pacman             # paquets dépôts officiels
└── packages.aur                # paquets AUR
```

## Stack

- **Shell** : zsh
- **DE** : KDE Plasma 6 (Wayland)
- **GPU** : NVIDIA RTX 3070 + AMD Vega (hybride via envycontrol)
- **Audio** : Pipewire + REAPER + yabridge (VST Windows)
- **Virtualisation** : QEMU + virt-manager + distrobox
