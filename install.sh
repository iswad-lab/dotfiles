#!/bin/bash
# =============================================================================
# install.sh — bootstrap dotfiles from GitHub
# Usage: sh -c "$(curl -fsLS https://raw.githubusercontent.com/iswad-lab/dotfiles/main/install.sh)"
# =============================================================================
set -e

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
