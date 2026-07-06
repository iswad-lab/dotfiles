#!/bin/bash
# =============================================================================
# run_once_07-ryzenadj.sh
# Run once by chezmoi (re-runs if this file changes)
# Install RyzenAdj power profile service + udev rule for Ryzen 5800H
# =============================================================================
set -e

SCRIPT_DIR="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}"

echo ">>> Installing ryzenadj-profile..."

# Copy the profile script
sudo cp "$SCRIPT_DIR/dot_local/bin/ryzenadj-profile" /usr/local/bin/ryzenadj-profile
sudo chmod +x /usr/local/bin/ryzenadj-profile

# Write systemd service
sudo tee /etc/systemd/system/ryzenadj-profile.service > /dev/null << 'EOF'
[Unit]
Description=RyzenAdj profile - AC/battery power & temperature limits
After=multi-user.target nvidia-powerd.service
Wants=nvidia-powerd.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ryzenadj-profile auto
RemainAfterExit=yes
Nice=-5

[Install]
WantedBy=multi-user.target
EOF

# Write udev rule for AC plug/unplug
sudo tee /etc/udev/rules.d/99-ryzenadj-profile.rules > /dev/null << 'EOF'
SUBSYSTEM=="power_supply", KERNEL=="ACAD", ATTR{online}=="1", RUN+="/usr/local/bin/ryzenadj-profile ac"
SUBSYSTEM=="power_supply", KERNEL=="ACAD", ATTR{online}=="0", RUN+="/usr/local/bin/ryzenadj-profile battery"
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable ryzenadj-profile.service
sudo systemctl start ryzenadj-profile.service

# Reload udev rules
sudo udevadm control --reload-rules

echo ">>> RyzenAdj profile setup complete."
