#!/bin/bash
# =============================================================================
# run_once_05-nbfc.sh
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
./autogen.sh
./configure --prefix=/usr --sysconfdir=/etc --bindir=/usr/bin
make
sudo make install

echo ">>> Building nbfc-qt from iswad-lab/nbfc-qt..."

git clone --depth=1 https://github.com/iswad-lab/nbfc-qt "$WORKDIR/nbfc-qt"
cd "$WORKDIR/nbfc-qt"
make QT_VERSION=6
sudo make install

echo ">>> nbfc-linux and nbfc-qt installed successfully."

echo ">>> Configuring nbfc profile and service..."

# Copy custom fan profile
sudo mkdir -p /usr/share/nbfc/configs
sudo tee /usr/share/nbfc/configs/isma-nbfc.json > /dev/null < "$(chezmoi source-path)/isma-nbfc.json"

# Write service config to use the profile
sudo mkdir -p /etc/nbfc
echo '{"SelectedConfigId": "isma-nbfc"}' | sudo tee /etc/nbfc/nbfc.json > /dev/null

# Enable and restart service
# Kill old process if hanging (nvidia sensor passthrough)
sudo systemctl daemon-reload
sudo pkill -9 nbfc_service 2>/dev/null || true
sudo systemctl enable nbfc_service.service
sudo systemctl start nbfc_service.service

echo ">>> NBFC setup complete."
