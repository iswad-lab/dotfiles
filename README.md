# Dotfiles — Iswad

Reproducible setup for **CachyOS x86_64** + KDE Plasma 6 + NVIDIA RTX 3070 / AMD Vega hybrid.

## Installation

```bash
sh -c "$(curl -fsLS https://raw.githubusercontent.com/iswad-lab/dotfiles/main/install.sh)"
```

## Structure

```
dotfiles/
├── install.sh                        # bootstrap (paru + chezmoi + apply)
├── run_once_01-packages.sh           # pacman + AUR packages
├── run_once_02-wine-staging.sh       # wine-staging 9.21 (yabridge compat)
├── run_once_03-libvirt-setup.sh      # libvirt services + groups
├── run_once_04-vfio-setup.sh         # GPU passthrough (VFIO)
├── run_once_05-nbfc.sh               # nbfc-linux + nbfc-qt (forks)
├── packages.pacman                   # official repo packages
├── packages.aur                      # AUR packages
├── isma-nbfc.json                    # custom fan profile (NBFC)
├── dot_zshrc                         # zsh aliases
└── dot_local/
    └── bin/
        ├── limine-boot-win           # one-time boot to Windows
        └── limine-boot-vfio          # one-time boot to VFIO kernel
```

## Stack

- **Shell**: zsh + Powerlevel10k
- **DE**: KDE Plasma 6 (Wayland)
- **GPU**: NVIDIA RTX 3070 + AMD Vega (hybrid via envycontrol / VFIO)
- **Audio**: Pipewire + REAPER + yabridge (Windows VST bridge)
- **Virtualization**: QEMU + virt-manager + distrobox
- **Fan control**: nbfc-linux (fork iswad-lab)

## Aliases

- `ff` — fastfetch
- `win` / `ww` / `windows` — reboot to Windows (via Limine)
- `pass` / `pp` — reboot to VFIO GPU passthrough kernel

## Notes

- **SSH keys** (`~/.ssh/id_*`) : backup manuelle avant réinstall — trop sensibles pour les dotfiles
