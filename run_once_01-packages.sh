#!/bin/bash
# =============================================================================
# run_once_01-packages.sh
# Run once by chezmoi (re-runs if this file changes)
# =============================================================================
set -e

# Ensure paru is available
if ! command -v paru &>/dev/null; then
  echo "ERROR: paru is not installed. Run install.sh first."
  exit 1
fi

SCRIPT_DIR="$(chezmoi source-path)"
PACMAN_LIST="$SCRIPT_DIR/packages.pacman"
AUR_LIST="$SCRIPT_DIR/packages.aur"

parse_list() {
  grep -v '^\s*#' "$1" | grep -v '^\s*$' | awk '{print $1}'
}

# --- Replace jack2 with pipewire-jack ----------------------------------------
if pacman -Q jack2 &>/dev/null; then
  echo ">>> jack2 detected, replacing with pipewire-jack..."
  sudo pacman -Rdd --noconfirm jack2
fi

# --- Official packages -------------------------------------------------------
echo ">>> Installing pacman packages..."
sudo pacman -S --needed --noconfirm $(parse_list "$PACMAN_LIST" | tr '\n' ' ')

# --- AUR packages ------------------------------------------------------------
echo ">>> Installing AUR packages..."
paru -S --needed --noconfirm $(parse_list "$AUR_LIST" | tr '\n' ' ')

echo ">>> Packages installed successfully."
