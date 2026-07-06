#!/bin/bash
# =============================================================================
# run_once_06-libvirt-setup.sh
# Run once by chezmoi (re-runs if this file changes)
# Post-install configuration for libvirt / QEMU
# =============================================================================
set -e

echo ">>> Enabling libvirt services..."

# Enable socket activation (services start on demand)
for drv in qemu interface network nodedev nwfilter secret storage; do
  sudo systemctl enable "virt${drv}d.socket"
  sudo systemctl start  "virt${drv}d.socket"
done

echo ">>> Adding user to libvirt and kvm groups..."
sudo usermod -aG libvirt,kvm "$USER"

echo ">>> Setting default network to autostart..."
sudo virsh net-autostart default 2>/dev/null || true
sudo virsh net-start default 2>/dev/null || true

echo ">>> libvirt setup complete."
