#!/bin/bash
# =============================================================================
# run_once_02-wine-staging.sh
# Install wine-staging 9.21 (last version compatible with yabridge 5.1.1)
# and lock it in pacman.conf to prevent automatic upgrades
# Idempotent: safe to re-run, skips if already set up
# =============================================================================
set -e

WINE_VERSION="9.21-1"
WINE_PKG="wine-staging-${WINE_VERSION}-x86_64.pkg.tar.zst"
ALA_URL="https://archive.archlinux.org/packages/w/wine-staging/${WINE_PKG}"

# --- Check if wine 9.21 is already installed -----------------------------------
CURRENT_WINE=$(wine --version 2>/dev/null || echo "")
if echo "$CURRENT_WINE" | grep -q "wine-9.21"; then
  echo ">>> wine-staging 9.21 already installed, skipping install"
else
  # Remove conflicting wine packages if present
  for pkg in wine wine-cachyos; do
    if pacman -Q 2>/dev/null | grep -q "^$pkg "; then
      echo ">>> Removing conflicting package: $pkg"
      sudo pacman -Rdd --noconfirm "$pkg"
    fi
  done

  # Download and install wine-staging 9.21
  echo ">>> Downloading wine-staging ${WINE_VERSION}..."
  tmpdir=$(mktemp -d)
  curl -fL --output "$tmpdir/$WINE_PKG" "$ALA_URL" || { echo "ERROR: Download failed"; exit 1; }
  echo ">>> Installing wine-staging ${WINE_VERSION}..."
  sudo pacman -U --noconfirm "$tmpdir/$WINE_PKG"
  rm -rf "$tmpdir"
fi

# --- Lock wine-staging in IgnorePkg (idempotent) --------------------------------
if grep -q "^IgnorePkg" /etc/pacman.conf; then
  if ! grep -q "wine-staging" /etc/pacman.conf; then
    echo ">>> Adding wine-staging to IgnorePkg..."
    sudo sed -i 's/^IgnorePkg\s*=\s*/IgnorePkg = wine-staging /' /etc/pacman.conf
  fi
else
  echo ">>> Adding IgnorePkg = wine-staging..."
  sudo sed -i 's/^#IgnorePkg.*/IgnorePkg = wine-staging/' /etc/pacman.conf
fi

# --- Initialize Wine prefix only if not already done ---------------------------
WINE_PREFIX="$HOME/.wine"
if [ -d "$WINE_PREFIX/drive_c" ]; then
  echo ">>> Wine prefix already exists, skipping initialization"
else
  echo ">>> Initializing Wine prefix..."
  WINEDLLOVERRIDES="winemenubuilder.exe=d" wine wineboot -u 2>/dev/null

  # Install core fonts for plugin GUI compatibility
  echo ">>> Installing corefonts via winetricks..."
  WINEDLLOVERRIDES="winemenubuilder.exe=d" winetricks -q corefonts 2>/dev/null
fi

echo ">>> Wine setup complete."
