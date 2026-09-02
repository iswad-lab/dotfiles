#!/bin/bash
# =============================================================================
# run_once_06-libvirt-setup.sh
# Run once by chezmoi (re-runs if this file changes)
# Post-install configuration for libvirt / QEMU
# =============================================================================
set -e

# Logging helpers: .lib_logging.sh ships in the chezmoi source dir and is always
# present when run_once scripts run under chezmoi, so no fallback is needed.
source "${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}/.lib_logging.sh"

log_info "Enabling libvirt services..."

# Enable socket activation (services start on demand)
for drv in qemu interface network nodedev nwfilter secret storage; do
  sudo systemctl enable "virt${drv}d.socket"
  sudo systemctl start  "virt${drv}d.socket"
done

log_info "Adding user to libvirt and kvm groups..."
sudo usermod -aG libvirt,kvm "$USER"

log_info "Setting default network to autostart..."
sudo virsh net-autostart default 2>/dev/null || true
sudo virsh net-start default 2>/dev/null || true

log_pass "libvirt setup complete."
