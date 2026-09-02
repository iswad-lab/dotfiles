# My Dotfiles

Reproducible setup for **CachyOS x86_64** (KDE Plasma 6, Wayland).

## Installation

```bash
sh -c "$(curl -fsLS https://raw.githubusercontent.com/ismail-bahloul/dotfiles/main/install.sh)"
```

## Structure

```
dotfiles/
├── install.sh                        # bootstrap (paru + chezmoi + apply, --dry-run)
├── validate.sh                       # post-install verification script
├── run_once_01-packages.sh           # pacman + AUR packages
├── run_once_02-wine-staging.sh       # wine-staging 9.21 standalone runner
├── run_once_03-nbfc.sh               # nbfc-linux + nbfc-qt (forks)
├── run_once_04-power-profile.sh      # RyzenAdj + NVIDIA power profiles + EC re-apply timer
├── run_once_05-vfio-setup.sh         # GPU passthrough (VFIO)
├── run_once_06-libvirt-setup.sh      # libvirt services + groups
├── run_once_07-looking-glass.sh      # Looking Glass shared memory
├── run_once_08-kde-settings.sh       # KDE settings enforced via kwriteconfig6
├── packages.pacman                   # official repo packages
├── packages.aur                      # AUR packages
├── my-nbfc.json                       # custom fan profile (NBFC)
├── create_dot_config/                 # created only if absent (Plasma owns it afterwards)
│   └── plasma-*.appletsrc             # panel/widgets layout (volatile → apply once)
├── dot_config/
│   ├── gh/                           # GitHub CLI config
│   ├── pipewire/pipewire.conf.d/      # PipeWire: global quantum + proprietary RME mode (TuxMix)
│   ├── wireplumber/wireplumber.conf.d/# WirePlumber: per-interface RME (CC) rules + Ryzen onboard
│   └── *.rc                           # KDE Plasma config (shortcuts, panel, kwin)
├── dot_local/
│   ├── bin/                          # boot scripts, profiles
│   │   ├── limine-boot-win           # one-time boot to Windows
│   │   ├── limine-boot-vfio          # one-time boot to VFIO kernel
│   │   ├── limine-boot-linux         # restore boot to Linux
│   │   ├── backup-data               # backup DATA to external drive
│   │   └── power-profile             # CPU/GPU power management
│   └── share/plasma/plasmoids/       # KDE widgets (thermal monitor, salat)
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
| **Display** | LG UltraGear 27GP850 (2560x1440 @ 144 Hz, DP, wired to the dGPU: no external output on the iGPU) |

## Stack

- **OS**: Dualboot (Linux CachyOS + Windows 11)
- **Shell**: zsh + Powerlevel10k
- **DE**: KDE Plasma 6 (Wayland)
- **GPU**: NVIDIA RTX 3070 + AMD Vega (VFIO passthrough for VM)
- **Audio**: Pipewire (JACK) + REAPER + yabridge (Windows VST bridge)
- **Virtualization**: QEMU + virt-manager + distrobox
- **Fan control**: nbfc-linux (fork ismail-bahloul)
- **Power mgmt**: RyzenAdj + NVIDIA power profiles (AC/battery auto, re-applied every 5 min against EC/firmware override)
- **Wine**: wine-staging 9.21 standalone runner (~/.local/share/wine-runners/)
- **Peripherals**: Logitech MX Master 3S (logiops)

## Aliases

| Alias | Action |
|---|---|
| `ff` | fastfetch |
| `ww` | One-time boot to Windows |
| `vv` | One-time boot to VFIO GPU passthrough kernel |
| `ll` | One-time boot to default Linux kernel |
| `backup` | Backup DATA to external drive |
| `power` | Show power profile status (CPU/GPU temps, limits, fans) |
| `balanced` | Reset to balanced profile (auto AC/battery) |
| `perf` | Switch to performance mode (4.4 GHz / GPU unlocked) |

## Notes

- **SSH keys** (`~/.ssh/id_*`): backup manually before reinstall (too sensitive for dotfiles).
- **KDE config** (shortcuts, panel, kwin) versioned in `dot_config/`.
- **Audio PipeWire** — config versioned in `dot_config/pipewire/` and
  `dot_config/wireplumber/`:
  - **RME Babyface Pro FS** switchable between **CC** mode (kernel driver,
    `51-rme.conf`) and **proprietary** mode (in-house TuxMix driver via
    `50-tuxmix.conf`) — see
    `dot_config/pipewire/pipewire.conf.d/README.md`.
  - **Per-interface quantum**: global = 64 (RME CC), but the internal Ryzen
    sound card forces 256 (`52-ryzen-quantum.conf`) — the 64 causes
    underruns there.
- These quantum/node-name rules are specific to this laptop (Ryzen
  `pci-0000_07_00.6`, RME USB) — not intended for other machines.
