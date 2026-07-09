#!/bin/bash
# =============================================================================
# install.sh — bootstrap dotfiles from GitHub
# Usage: sh -c "$(curl -fsLS https://raw.githubusercontent.com/iswad-lab/dotfiles/main/install.sh)"
#        ./install.sh           # normal install
#        ./install.sh --dry-run # check prerequisites only, no install
# =============================================================================
set -e

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
  echo ">>> DRY RUN — checking prerequisites only"
  echo ""
fi

# --- Prerequisites check ----------------------------------------------------
echo ">>> Checking prerequisites..."

# Check if running on Arch-based
if [ ! -f /etc/arch-release ] && [ ! -f /etc/cachyos-release ]; then
  echo "ERROR: This install script is for Arch Linux / CachyOS only."
  exit 1
fi
echo "  ✓ Arch / CachyOS detected"

# Check not running as root (makepkg refuses)
if [ "$(id -u)" = "0" ]; then
  echo "ERROR: Do not run as root. Run as a normal user with sudo access."
  exit 1
fi
echo "  ✓ Not root"

# Check internet
if ! ping -c1 archlinux.org &>/dev/null 2>&1; then
  echo "ERROR: No internet connection."
  exit 1
fi
echo "  ✓ Internet OK"

if $DRY_RUN; then
  echo ""
  echo ">>> All prerequisites OK. Run without --dry-run to install."
  exit 0
fi

# --- paru --------------------------------------------------------------------
if ! command -v paru &>/dev/null; then
  echo ">>> Installing paru..."
  sudo pacman -S --needed --noconfirm base-devel git
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
  (cd "$tmpdir/paru" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
fi

# --- chezmoi -----------------------------------------------------------------
if ! command -v chezmoi &>/dev/null; then
  echo ">>> Installing chezmoi..."
  sudo pacman -S --needed --noconfirm chezmoi
fi

# Clear any stale lock (e.g. from interrupted previous install)
rm -f "$HOME/.local/share/chezmoi/.chezmoi.lock"

# --- Apply dotfiles ----------------------------------------------------------
echo ">>> Applying dotfiles from GitHub..."
# If chezmoi already initialized, use update instead of init --apply
if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
  chezmoi update --apply 2>/dev/null || chezmoi init --apply https://github.com/iswad-lab/dotfiles
else
  chezmoi init --apply https://github.com/iswad-lab/dotfiles
fi

echo ""
echo ">>> Done. Restart your session to apply all changes."
echo ""

# Run validation (download from repo, run locally)
echo ">>> Running post-install validation..."
curl -fsLS "https://raw.githubusercontent.com/iswad-lab/dotfiles/main/validate.sh" | bash
