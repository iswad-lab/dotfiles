#!/bin/bash
# =============================================================================
# run_once_08-kde-settings.sh
# Run once by chezmoi (re-runs if this file changes)
# KDE Plasma 6 — enforce the settings we care about via kwriteconfig6
#
# Why: kwinrc / plasma appletsrc are rewritten by Plasma at runtime.
# Versioning them as whole files causes drift and `chezmoi apply` clobbers
# runtime tweaks. So we only *impose* the settings below; Plasma stays the
# owner of everything else.
#
# The volatile files themselves are handled like this:
#   - kwinrc  → versioned, but stripped of per-window [Tiling] UUID noise
#   - appletsrc → create_ prefix (deployed only on fresh install)
# =============================================================================
set -e

# Logging helpers: .lib_logging.sh ships in the chezmoi source dir and is always
# present when run_once scripts run under chezmoi, so no fallback is needed.
source "${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}/.lib_logging.sh"

if ! command -v kwriteconfig6 &>/dev/null; then
  log_fatal "kwriteconfig6 not found (KDE Plasma required)"
fi

# --- KWin: effect plugins ---------------------------------------------------
log_info "KWin: effect plugins..."
kwriteconfig6 --file kwinrc --group Plugins --key better_blur_dxEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key translucencyEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key wobblywindowsEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled false

# --- KWin: better-blur effect settings --------------------------------------
log_info "KWin: better-blur effect..."
kwriteconfig6 --file kwinrc --group Effect-better-blur-dx --key BlurDecorations true
kwriteconfig6 --file kwinrc --group Effect-better-blur-dx --key BlurDocks true
kwriteconfig6 --file kwinrc --group Effect-better-blur-dx --key BlurMatching false
kwriteconfig6 --file kwinrc --group Effect-better-blur-dx --key BlurMenus true
kwriteconfig6 --file kwinrc --group Effect-better-blur-dx --key BlurNonMatching true

# --- KWin: desktops & Xwayland ----------------------------------------------
log_info "KWin: desktops / Xwayland..."
kwriteconfig6 --file kwinrc --group Desktops --key Number 2
kwriteconfig6 --file kwinrc --group Desktops --key Rows 1
kwriteconfig6 --file kwinrc --group Xwayland --key Scale 1

# --- Plasma desktop: middle-click paste / right-click menu --------------------
log_info "Plasma: desktop click actions..."
kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group ActionPlugins --group 0 --key 'MiddleButton;NoModifier' org.kde.paste
kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group ActionPlugins --group 0 --key 'RightButton;NoModifier' org.kde.contextmenu
kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group ActionPlugins --group 1 --key 'RightButton;NoModifier' org.kde.contextmenu

# --- Apply without logout (best-effort) --------------------------------------
log_info "Reloading KWin config..."
if command -v qdbus6 &>/dev/null; then
  qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
elif command -v qdbus &>/dev/null; then
  qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

log_pass "KDE settings applied."
