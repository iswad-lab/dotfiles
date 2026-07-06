# Dotfiles — Iswad

Reproducible setup for **CachyOS x86_64** — KDE Plasma 6 (Wayland).

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
├── run_once_03-vfio-setup.sh         # GPU passthrough (VFIO)
├── run_once_04-nbfc.sh               # nbfc-linux + nbfc-qt (forks)
├── run_once_05-power-profile.sh      # RyzenAdj + NVIDIA power profiles
├── run_once_06-libvirt-setup.sh      # libvirt services + groups
├── run_once_07-looking-glass.sh      # Looking Glass shared memory
├── packages.pacman                   # official repo packages
├── packages.aur                      # AUR packages
├── iswad-nbfc.json                    # custom fan profile (NBFC)
├── dot_zshrc                         # zsh aliases
└── dot_local/
    └── bin/
        ├── limine-boot-win           # one-time boot to Windows
        └── limine-boot-vfio          # one-time boot to VFIO kernel
```

## Hardware

| Component | Model |
|---|---|
| **Laptop** | HP OMEN 15-en1xxx (15-en1022nf) |
| **CPU** | AMD Ryzen 7 5800H (8C/16T, Zen 3) |
| **iGPU** | AMD Radeon Graphics (Vega) |
| **dGPU** | NVIDIA GeForce RTX 3070 Mobile (GA104, 8 GB GDDR6) |
| **RAM** | 2× 16 GB DDR4-3200 |
| **Storage** | SK Hynix 512 GB (NVMe) + Crucial 1 TB (NVMe) |
| **Network** | Realtek RTL8111/8168 (Ethernet) + Intel Wi-Fi 6 AX200 |

## Stack

- **OS**: Dualboot — Linux (CachyOS) + Windows 11
- **Shell**: zsh + Powerlevel10k
- **DE**: KDE Plasma 6 (Wayland)
- **GPU**: NVIDIA RTX 3070 + AMD Vega — VFIO passthrough for VM
- **Audio**: Pipewire (JACK) + REAPER + yabridge (Windows VST bridge)
- **Virtualization**: QEMU + virt-manager + distrobox
- **Fan control**: nbfc-linux (fork iswad-lab)

## Aliases

| Alias | Action |
|---|---|
| `ff` | fastfetch |
| `ww` / `win` / `windows` | One-time boot to Windows (via Limine) |
| `pp` / `pass` | One-time boot to VFIO GPU passthrough kernel |
| `ll` / `linux` | One-time boot to default Linux kernel |
| `backup-data` | Backup DATA to external drive |

## Notes

- **SSH keys** (`~/.ssh/id_*`): backup manually before reinstall — too sensitive for dotfiles.
- **KDE config** is intentionally not versioned (too volatile).
