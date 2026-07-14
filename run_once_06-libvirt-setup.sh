#!/bin/bash
# =============================================================================
# run_once_06-libvirt-setup.sh
# Run once by chezmoi (re-runs if this file changes)
# Post-install configuration for libvirt / QEMU
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
