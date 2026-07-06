#!/bin/bash
# =============================================================================
# run_once_05-power-profile.sh
# Run once by chezmoi (re-runs if this file changes)
# Install power-profile service + udev rule (RyzenAdj + NVIDIA + CPU governor)
# =============================================================================
set -e

SCRIPT_DIR="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}"

echo ">>> Installing power-profile..."

# Copy the profile script
sudo cp "$SCRIPT_DIR/dot_local/bin/power-profile" /usr/local/bin/power-profile
sudo chmod +x /usr/local/bin/power-profile

# Remove old service/udev if they exist (from ryzenadj-profile rename)
sudo rm -f /etc/systemd/system/ryzenadj-profile.service /etc/udev/rules.d/99-ryzenadj-profile.rules
sudo systemctl daemon-reload 2>/dev/null

# Write systemd service
sudo tee /etc/systemd/system/power-profile.service > /dev/null << 'EOF'
[Unit]
Description=Power profile - AC/battery CPU/GPU power & temp limits
After=multi-user.target nvidia-powerd.service
Wants=nvidia-powerd.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/power-profile auto
RemainAfterExit=yes
Nice=-5

[Install]
WantedBy=multi-user.target
EOF

# Write udev rule for AC plug/unplug
sudo tee /etc/udev/rules.d/99-power-profile.rules > /dev/null << 'EOF'
SUBSYSTEM=="power_supply", KERNEL=="ACAD", ATTR{online}=="1", RUN+="/usr/local/bin/power-profile ac"
SUBSYSTEM=="power_supply", KERNEL=="ACAD", ATTR{online}=="0", RUN+="/usr/local/bin/power-profile battery"
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable power-profile.service
sudo systemctl start power-profile.service

# Enable NVIDIA services
sudo systemctl enable --now nvidia-powerd.service 2>/dev/null || true
sudo systemctl enable nvidia-suspend.service nvidia-resume.service 2>/dev/null || true

# Reload udev rules
sudo udevadm control --reload-rules

echo ">>> Power profile setup complete."
