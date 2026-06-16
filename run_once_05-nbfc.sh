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
./autogen.sh > /dev/null
./configure --prefix=/usr --sysconfdir=/etc --bindir=/usr/bin > /dev/null
make > /dev/null
sudo make install > /dev/null

echo ">>> Building nbfc-qt from iswad-lab/nbfc-qt..."

git clone --depth=1 https://github.com/iswad-lab/nbfc-qt "$WORKDIR/nbfc-qt"
cd "$WORKDIR/nbfc-qt"
make QT_VERSION=6 > /dev/null
sudo make install > /dev/null

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
sudo tee /usr/share/nbfc/configs/isma-nbfc.json > /dev/null << 'EOF'
{
  "NotebookModel": "isma-nbfc",
  "Author": "Isma",
  "Comment": "PATH: /usr/share/nbfc/configs/",
  "EcPollInterval": 1000,
  "ReadWriteWords": false,
  "CriticalTemperature": 100,
  "FanConfigurations": [
    {
      "ReadRegister": 46,
      "WriteRegister": 44,
      "MinSpeedValue": 0,
      "MaxSpeedValue": 100,
      "IndependentReadMinMaxValues": false,
      "MinSpeedValueRead": 0,
      "MaxSpeedValueRead": 0,
      "ResetRequired": true,
      "FanSpeedResetValue": 255,
      "FanDisplayName": "CPU fan",
      "TemperatureThresholds": [
        {"UpThreshold": 49, "DownThreshold": 0, "FanSpeed": 12},
        {"UpThreshold": 58, "DownThreshold": 49, "FanSpeed": 16},
        {"UpThreshold": 62, "DownThreshold": 56, "FanSpeed": 20},
        {"UpThreshold": 66, "DownThreshold": 60, "FanSpeed": 24},
        {"UpThreshold": 71, "DownThreshold": 64, "FanSpeed": 29},
        {"UpThreshold": 76, "DownThreshold": 67, "FanSpeed": 35},
        {"UpThreshold": 78, "DownThreshold": 72, "FanSpeed": 41},
        {"UpThreshold": 86, "DownThreshold": 78, "FanSpeed": 66},
        {"UpThreshold": 90, "DownThreshold": 84, "FanSpeed": 81},
        {"UpThreshold": 93, "DownThreshold": 89, "FanSpeed": 90},
        {"UpThreshold": 100, "DownThreshold": 91, "FanSpeed": 100}
      ]
    },
    {
      "ReadRegister": 47,
      "WriteRegister": 45,
      "MinSpeedValue": 0,
      "MaxSpeedValue": 100,
      "IndependentReadMinMaxValues": false,
      "MinSpeedValueRead": 0,
      "MaxSpeedValueRead": 0,
      "ResetRequired": true,
      "FanSpeedResetValue": 255,
      "FanDisplayName": "GPU fan",
      "Sensors": ["@GPU"],
      "TemperatureThresholds": [
        {"UpThreshold": 49, "DownThreshold": 0, "FanSpeed": 12},
        {"UpThreshold": 58, "DownThreshold": 49, "FanSpeed": 16},
        {"UpThreshold": 62, "DownThreshold": 56, "FanSpeed": 22},
        {"UpThreshold": 66, "DownThreshold": 60, "FanSpeed": 26},
        {"UpThreshold": 71, "DownThreshold": 64, "FanSpeed": 29},
        {"UpThreshold": 76, "DownThreshold": 67, "FanSpeed": 35},
        {"UpThreshold": 78, "DownThreshold": 74, "FanSpeed": 50},
        {"UpThreshold": 82, "DownThreshold": 68, "FanSpeed": 75},
        {"UpThreshold": 90, "DownThreshold": 76, "FanSpeed": 80},
        {"UpThreshold": 93, "DownThreshold": 89, "FanSpeed": 90},
        {"UpThreshold": 95, "DownThreshold": 91, "FanSpeed": 100}
      ]
    }
  ]
}
EOF

# Write service config to use the profile
sudo mkdir -p /etc/nbfc
echo '{"SelectedConfigId": "isma-nbfc"}' | sudo tee /etc/nbfc/nbfc.json > /dev/null

# Enable and restart service
sudo systemctl daemon-reload
sudo systemctl enable nbfc_service.service
sudo nbfc restart

echo ">>> NBFC setup complete."
