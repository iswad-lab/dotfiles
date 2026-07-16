#!/bin/bash
# =============================================================================
# run_once_04-power-profile.sh
# Run once by chezmoi (re-runs if this file changes)
# Install power-profile service + udev rule (RyzenAdj + NVIDIA + CPU governor)
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

SCRIPT_DIR="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}"

log_info "Installing power-profile..."

# Disable power-profiles-daemon if present (conflicts with our setup)
if [ -f /usr/lib/systemd/system/power-profiles-daemon.service ]; then
  log_info "power-profiles-daemon detected, masking it..."
  sudo systemctl mask --now power-profiles-daemon.service 2>/dev/null || true
fi

# Copy the profile script
sudo cp "$SCRIPT_DIR/dot_local/bin/executable_power-profile" /usr/local/bin/power-profile
sudo chmod +x /usr/local/bin/power-profile

# Remove old service/udev if they exist (from ryzenadj-profile rename)
sudo rm -f /etc/systemd/system/ryzenadj-profile.service /etc/udev/rules.d/99-ryzenadj-profile.rules
sudo systemctl daemon-reload 2>/dev/null

# Write systemd service (triggered by timer + udev)
sudo tee /etc/systemd/system/power-profile.service > /dev/null << 'EOF'
[Unit]
Description=Power profile - AC/battery CPU/GPU power & temp limits

[Service]
Type=oneshot
ExecStart=/usr/local/bin/power-profile auto
RemainAfterExit=yes
Nice=-5

[Install]
WantedBy=multi-user.target
EOF

# Write systemd timer (delayed startup, ensures ryzenadj applies after all services)
sudo tee /etc/systemd/system/power-profile.timer > /dev/null << 'EOF'
[Unit]
Description=Power profile - delayed startup (30s after boot)

[Timer]
OnBootSec=30
Persistent=false

[Install]
WantedBy=timers.target
EOF

# Write udev rule for AC plug/unplug (calls 'auto' which detects AC/battery)
sudo tee /etc/udev/rules.d/99-power-profile.rules > /dev/null << 'EOF'
ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="ACAD", ATTR{online}=="1", RUN+="/usr/bin/systemd-run --no-block /usr/local/bin/power-profile auto"
ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="ACAD", ATTR{online}=="0", RUN+="/usr/bin/systemd-run --no-block /usr/local/bin/power-profile auto"
EOF

# Set swappiness (lower = avoid disk swap, good for NVMe)
# Note: skipped if zram is active (zram prefers higher swappiness)
if ! lsblk | grep -q zram; then
  echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null
  sudo sysctl -w vm.swappiness=10 > /dev/null
fi

# Enable and start service + timer
sudo systemctl daemon-reload
sudo systemctl enable power-profile.service
sudo systemctl enable --now power-profile.timer
sudo systemctl start power-profile.service

# Enable NVIDIA services (suspend/resume only)
sudo systemctl enable nvidia-suspend.service nvidia-resume.service 2>/dev/null || true

# Reload udev rules
sudo udevadm control --reload-rules

log_pass "Power profile setup complete."
