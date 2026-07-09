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

# Check internet
if ! ping -c1 archlinux.org &>/dev/null 2>&1; then
  echo "ERROR: No internet connection."
  exit 1
fi
echo "  ✓ Internet OK"

# Check sudo
if ! sudo -n true 2>/dev/null; then
  echo "ERROR: Sudo required. Run with a user that has sudo access."
  exit 1
fi
echo "  ✓ Sudo OK"

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

# --- Apply dotfiles ----------------------------------------------------------
echo ">>> Applying dotfiles from GitHub..."
chezmoi init --apply https://github.com/iswad-lab/dotfiles

echo ""
echo ">>> Done. Restart your session to apply all changes."
echo "    Run validate.sh to verify deployment."
