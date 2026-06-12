#!/bin/bash
# =============================================================================
# install.sh — bootstrap dotfiles depuis GitHub
# Usage : sh -c "$(curl -fsLS https://raw.githubusercontent.com/iswad/dotfiles/main/install.sh)"
# =============================================================================
set -e

# --- paru --------------------------------------------------------------------
if ! command -v paru &>/dev/null; then
  echo ">>> Installation de paru..."
  sudo pacman -S --needed --noconfirm base-devel git
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
  (cd "$tmpdir/paru" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
fi

# --- chezmoi -----------------------------------------------------------------
if ! command -v chezmoi &>/dev/null; then
  echo ">>> Installation de chezmoi..."
  sudo pacman -S --needed --noconfirm chezmoi
fi

# --- Apply dotfiles ----------------------------------------------------------
echo ">>> Application des dotfiles depuis GitHub..."
chezmoi init --apply https://github.com/iswad/dotfiles

echo ""
echo ">>> Done. Relance ta session pour appliquer tous les changements."
