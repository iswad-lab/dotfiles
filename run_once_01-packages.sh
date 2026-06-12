#!/bin/bash
# =============================================================================
# run_once_01-packages.sh
# Installé une seule fois par chezmoi (re-run si le fichier change)
# =============================================================================
set -e

SCRIPT_DIR="$(dirname "$(chezmoi source-path)")"
PACMAN_LIST="$SCRIPT_DIR/packages.pacman"
AUR_LIST="$SCRIPT_DIR/packages.aur"

parse_list() {
  grep -v '^\s*#' "$1" | grep -v '^\s*$' | awk '{print $1}'
}

# --- Remplacer jack2 par pipewire-jack ---------------------------------------
if pacman -Q jack2 &>/dev/null; then
  echo ">>> jack2 détecté, remplacement par pipewire-jack..."
  sudo pacman -Rdd --noconfirm jack2
fi

# --- Paquets officiels -------------------------------------------------------
echo ">>> Installation des paquets pacman..."
sudo pacman -S --needed --noconfirm $(parse_list "$PACMAN_LIST" | tr '\n' ' ')

# --- Paquets AUR -------------------------------------------------------------
echo ">>> Installation des paquets AUR..."
paru -S --needed --noconfirm $(parse_list "$AUR_LIST" | tr '\n' ' ')

echo ">>> Paquets installés avec succès."
