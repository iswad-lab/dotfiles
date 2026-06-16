#!/bin/bash
# =============================================================================
# run_once_02-wine-staging.sh
# Install wine-staging 9.21 (last version compatible with yabridge 5.1.1)
# and lock it in pacman.conf to prevent automatic upgrades
# =============================================================================
set -e

WINE_VERSION="9.21-1"
WINE_PKG="wine-staging-${WINE_VERSION}-x86_64.pkg.tar.zst"
ALA_URL="https://archive.archlinux.org/packages/w/wine-staging/${WINE_PKG}"

# Remove conflicting wine packages if present
for pkg in wine wine-cachyos; do
  # Check real package name (not virtual provider)
  if pacman -Q 2>/dev/null | grep -q "^$pkg "; then
    echo ">>> Removing conflicting package: $pkg"
    sudo pacman -Rdd --noconfirm "$pkg"
  fi
done

# Download and install wine-staging 9.21
echo ">>> Downloading wine-staging ${WINE_VERSION}..."
tmpdir=$(mktemp -d)
curl -L --output "$tmpdir/$WINE_PKG" "$ALA_URL"
echo ">>> Installing wine-staging ${WINE_VERSION}..."
sudo pacman -U --noconfirm "$tmpdir/$WINE_PKG"
rm -rf "$tmpdir"

# Lock wine-staging in IgnorePkg
if grep -q "^IgnorePkg" /etc/pacman.conf; then
  # IgnorePkg line exists — append wine-staging if not already there
  if ! grep -q "wine-staging" /etc/pacman.conf; then
    sudo sed -i 's/^IgnorePkg\s*=\s*/IgnorePkg = wine-staging /' /etc/pacman.conf
  fi
else
  # No IgnorePkg line — add one
  sudo sed -i 's/^#IgnorePkg.*/IgnorePkg = wine-staging/' /etc/pacman.conf
fi

echo ">>> wine-staging ${WINE_VERSION} installed and locked in IgnorePkg."

# Initialize Wine prefix
echo ">>> Initializing Wine prefix..."
wine wineboot

# Install core fonts for plugin GUI compatibility
echo ">>> Installing corefonts via winetricks..."
winetricks -q corefonts

echo ">>> Wine setup complete."
