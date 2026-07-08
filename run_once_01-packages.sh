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

SCRIPT_DIR="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}"
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
mapfile -t pacman_pkgs < <(parse_list "$PACMAN_LIST")
sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}"

# --- AUR packages ------------------------------------------------------------
echo ">>> Installing AUR packages..."
mapfile -t aur_pkgs < <(parse_list "$AUR_LIST")
paru -S --needed --noconfirm "${aur_pkgs[@]}"

echo ">>> Adding user to realtime group for audio..."
sudo usermod -aG realtime "$USER"

# --- Logitech mouse (MX Master 3S) ------------------------------------------
if command -v logid &>/dev/null; then
  echo ">>> Configuring Logitech MX Master 3S..."
  sudo tee /etc/logid.cfg > /dev/null << 'EOF'
devices: (
{
    name: "MX Master 3S";
    smartshift: { on: true; threshold: 30; };
    hiresscroll: { hires: false; invert: false; target: false; };
    dpi: 1000;
    buttons: (
        {
            cid: 0xc4;
            action = {
                type: "Gestures";
                gestures: (
                    { direction: "None"; mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_PLAYPAUSE"]; }; },
                    { direction: "Up"; mode: "OnInterval"; interval: 50; action = { type: "Keypress"; keys: ["KEY_VOLUMEUP"]; }; },
                    { direction: "Down"; mode: "OnInterval"; interval: 50; action = { type: "Keypress"; keys: ["KEY_VOLUMEDOWN"]; }; },
                    { direction: "Right"; mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_NEXTSONG"]; }; },
                    { direction: "Left"; mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_PREVIOUSSONG"]; }; }
                );
            };
        },
        {
            cid: 0xc3;
            action = { type: "Keypress"; keys: ["KEY_LEFTMETA", "KEY_Z"]; };
        }
    );
}
);
EOF
  sudo systemctl enable --now logid.service 2>/dev/null || true
fi

echo ">>> Packages installed successfully."
