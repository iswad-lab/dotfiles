#!/bin/bash
# =============================================================================
# run_once_03-nbfc.sh
# Run once by chezmoi (re-runs if this file changes)
# Build & install nbfc-linux and nbfc-qt from iswad-lab forks
# =============================================================================
set -e

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

echo ">>> Building nbfc-linux from iswad-lab/nbfc-linux..."

# Clean any previous manual install
sudo rm -f /usr/bin/nbfc-linux 2>/dev/null || true

git clone --depth=1 https://github.com/iswad-lab/nbfc-linux "$WORKDIR/nbfc-linux"
cd "$WORKDIR/nbfc-linux"
./autogen.sh > /dev/null 2>&1
./configure --prefix=/usr --sysconfdir=/etc --bindir=/usr/bin > /dev/null 2>&1
make > /dev/null 2>&1
sudo make install > /dev/null 2>&1

echo ">>> Building nbfc-qt from iswad-lab/nbfc-qt..."

git clone --depth=1 https://github.com/iswad-lab/nbfc-qt "$WORKDIR/nbfc-qt"
cd "$WORKDIR/nbfc-qt"
make QT_VERSION=6 > /dev/null 2>&1
sudo make install > /dev/null 2>&1

echo ">>> nbfc-linux and nbfc-qt installed successfully."

# Lock nbfc packages in IgnorePkg (built from source, not pacman)
if grep -q "^IgnorePkg" /etc/pacman.conf; then
  for pkg in nbfc-linux nbfc-qt; do
    if ! grep -q "$pkg" /etc/pacman.conf; then
      sudo sed -i "s/^IgnorePkg\s*=\s*/IgnorePkg = $pkg /" /etc/pacman.conf
    fi
  done
else
  sudo sed -i 's/^#IgnorePkg.*/IgnorePkg = nbfc-linux nbfc-qt/' /etc/pacman.conf
fi

echo ">>> Configuring nbfc profile and service..."

# Copy custom fan profile
sudo mkdir -p /usr/share/nbfc/configs

FAN_PROFILE="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}/iswad-nbfc.json"

if [ ! -f "$FAN_PROFILE" ]; then
  echo "ERROR: iswad-nbfc.json not found at $FAN_PROFILE"
  exit 1
fi

sudo cp "$FAN_PROFILE" /usr/share/nbfc/configs/

# Write service config to use the profile
sudo mkdir -p /etc/nbfc
echo '{"SelectedConfigId": "iswad-nbfc"}' | sudo tee /etc/nbfc/nbfc.json > /dev/null

# Enable and restart service
sudo systemctl daemon-reload
sudo systemctl enable nbfc_service.service
sudo nbfc restart

echo ">>> NBFC setup complete."
