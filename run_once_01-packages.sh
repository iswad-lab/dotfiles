#!/bin/bash
# =============================================================================
# run_once_01-packages.sh
# Run once by chezmoi (re-runs if this file changes)
# =============================================================================
set -e

source "${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}/.lib_logging.sh" 2>/dev/null || {
  log_section() { echo ""; echo "─── $1 ───"; }
  log_pass() { echo "  ✔ $1"; }
  log_fail() { echo "  ✘ $1"; }
  log_fatal() { echo "  ✘ $1"; exit 1; }
  log_warn() { echo "  ⚠ $1"; }
  log_info() { echo "  → $1"; }
  log_skip() { echo "  ⋯ $1"; }
  log_detail() { echo "    • $1"; }
  log_cmd() { echo "  $ $1"; }
  log_summary() { :; }
}

# Ensure paru is available
if ! command -v paru &>/dev/null; then
  log_fatal "paru is not installed. Run install.sh first."
fi

SCRIPT_DIR="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}"
PACMAN_LIST="$SCRIPT_DIR/packages.pacman"
AUR_LIST="$SCRIPT_DIR/packages.aur"

# Ensure passwordless sudo for wheel group (extends installer behavior)
if ! sudo grep -q "%wheel.*NOPASSWD" /etc/sudoers.d/* 2>/dev/null; then
  echo "%wheel ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/99-wheel-nopasswd > /dev/null
fi

parse_list() {
  grep -v '^\s*#' "$1" | grep -v '^\s*$' | awk '{print $1}'
}

# --- Replace jack2 with pipewire-jack ----------------------------------------
 if pacman -Q jack2 &>/dev/null; then
   log_info "jack2 detected, replacing with pipewire-jack..."
   sudo pacman -Rdd --noconfirm jack2
 fi

 # --- Official packages -------------------------------------------------------
 log_info "Installing pacman packages..."
 mapfile -t pacman_pkgs < <(parse_list "$PACMAN_LIST")
 
 # Handle nodejs → nodejs-lts-jod migration (if a package in the list needs it)
 if pacman -Q nodejs &>/dev/null; then
   for pkg in "${pacman_pkgs[@]}"; do
     dep=$(pacman -Si "$pkg" 2>/dev/null | grep -oP 'nodejs-lts-jod[^ ]*' | head -1)
     if [ -n "$dep" ]; then
       log_info "$pkg depends on $dep, replacing nodejs..."
       sudo pacman -Rdd --noconfirm nodejs 2>/dev/null || true
       break
     fi
   done
 fi
 
 sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}"

# --- AUR packages ------------------------------------------------------------
log_info "Installing AUR packages..."
mapfile -t aur_pkgs < <(parse_list "$AUR_LIST")
paru -S --needed --noconfirm "${aur_pkgs[@]}"

log_info "Adding user to realtime group for audio..."
sudo usermod -aG realtime "$USER"

# Ensure user is in wheel group for passwordless sudo
log_info "Ensuring user is in wheel group..."
sudo usermod -aG wheel "$USER"

# --- Logitech mouse (MX Master 3S) ------------------------------------------
if command -v logid &>/dev/null; then
  log_info "Configuring Logitech MX Master 3S..."
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

# --- Logitech keyboard (MX Keys S) ------------------------------------------
if command -v solaar &>/dev/null; then
  log_info "Configuring Logitech MX Keys S via Solaar..."
  systemctl --user enable --now solaar.service 2>/dev/null || true
  log_detail "Tune Fn lock / backlight / Easy Switch via the Solaar GUI (solaar)."
fi

log_pass "Packages installed successfully."
