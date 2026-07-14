#!/bin/bash
# =============================================================================
# run_once_02-wine-staging.sh
# Install wine-staging 9.21 (last version compatible with yabridge 5.1.1)
# and lock it in pacman.conf to prevent automatic upgrades
# Idempotent: safe to re-run, skips if already set up
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

WINE_VERSION="9.21-1"
WINE_PKG="wine-staging-${WINE_VERSION}-x86_64.pkg.tar.zst"
ALA_URL="https://archive.archlinux.org/packages/w/wine-staging/${WINE_PKG}"

# --- Check if wine 9.21 is already installed -----------------------------------
CURRENT_WINE=$(wine --version 2>/dev/null || echo "")
if echo "$CURRENT_WINE" | grep -q "wine-9.21"; then
  log_skip "wine-staging 9.21 already installed"
else
  # Remove conflicting wine packages if present
  for pkg in wine wine-cachyos; do
    if pacman -Q 2>/dev/null | grep -q "^$pkg "; then
      log_info "Removing conflicting package: $pkg"
      sudo pacman -Rdd --noconfirm "$pkg"
    fi
  done

  # Download and install wine-staging 9.21
  log_info "Downloading wine-staging ${WINE_VERSION}..."
  tmpdir=$(mktemp -d)
  curl -fL --output "$tmpdir/$WINE_PKG" "$ALA_URL" || log_fatal "Download failed"
  log_info "Installing wine-staging ${WINE_VERSION}..."
  sudo pacman -U --noconfirm "$tmpdir/$WINE_PKG"
  rm -rf "$tmpdir"
fi

# --- Lock wine-staging in IgnorePkg (idempotent) --------------------------------
if grep -q "^IgnorePkg" /etc/pacman.conf; then
  if ! grep -q "wine-staging" /etc/pacman.conf; then
    log_info "Adding wine-staging to IgnorePkg..."
    sudo sed -i 's/^IgnorePkg\s*=\s*/IgnorePkg = wine-staging /' /etc/pacman.conf
  fi
else
  log_info "Adding IgnorePkg = wine-staging..."
  sudo sed -i 's/^#IgnorePkg.*/IgnorePkg = wine-staging/' /etc/pacman.conf
fi

# --- Initialize Wine prefix only if not already done ---------------------------
WINE_PREFIX="$HOME/.wine"
if [ -d "$WINE_PREFIX/drive_c" ]; then
  log_skip "Wine prefix already exists"
else
  log_info "Initializing Wine prefix..."
  WINEDLLOVERRIDES="winemenubuilder.exe=d" wine wineboot -u 2>/dev/null

  # Install core fonts for plugin GUI compatibility
  log_info "Installing corefonts via winetricks..."
  WINEDLLOVERRIDES="winemenubuilder.exe=d" winetricks -q corefonts 2>/dev/null
fi

log_pass "Wine setup complete."
