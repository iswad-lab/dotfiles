#!/bin/bash
# =============================================================================
# run_once_04-vfio-setup.sh
# Run once by chezmoi (re-runs if this file changes)
# GPU passthrough (VFIO) — NVIDIA RTX 3070 Mobile
# =============================================================================
set -e

echo ">>> Configuring VFIO for GPU passthrough..."

# ---------------------------------------------------------------------------
# 1. Ensure VFIO modules in mkinitcpio.conf
# ---------------------------------------------------------------------------
MKINITCPIO="/etc/mkinitcpio.conf"
if grep -q "vfio_pci" "$MKINITCPIO"; then
  echo "    VFIO modules already present in mkinitcpio.conf"
else
  echo "    Adding VFIO modules to mkinitcpio.conf..."
  sudo sed -i 's/^MODULES=([^)]*)/MODULES=(vfio_pci vfio vfio_iommu_type1)/' "$MKINITCPIO"
fi

# ---------------------------------------------------------------------------
# 2. Create kernel cmdline snippet for VFIO (systemd kernel-install)
# ---------------------------------------------------------------------------
CMDLINE_DIR="/etc/cmdline.d"
CMDLINE_FILE="$CMDLINE_DIR/vfio.conf"

sudo mkdir -p "$CMDLINE_DIR"

if [ -f "$CMDLINE_FILE" ]; then
  echo "    $CMDLINE_FILE already exists, skipping"
else
  echo 'amd_iommu=on iommu=pt vfio-pci.ids=10de:249d,10de:228b' | sudo tee "$CMDLINE_FILE" > /dev/null
  echo "    Created $CMDLINE_FILE"
fi

# ---------------------------------------------------------------------------
# 3. Regenerate initramfs
# ---------------------------------------------------------------------------
echo ">>> Regenerating initramfs..."
sudo mkinitcpio -P

echo ">>> VFIO setup complete. Reboot required for changes to take effect."
