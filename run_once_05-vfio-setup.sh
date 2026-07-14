#!/bin/bash
# =============================================================================
# run_once_05-vfio-setup.sh
# Run once by chezmoi (re-runs if this file changes)
# GPU passthrough (VFIO) — NVIDIA RTX 3070 Mobile
# Idempotent: safe to re-run, mkinitcpio only if config changed
# =============================================================================
set -e

SCRIPT_DIR="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}"

echo ">>> Configuring VFIO for GPU passthrough..."

NEEDS_MKINITCPIO=false

# ---------------------------------------------------------------------------
# 1. Ensure VFIO modules in mkinitcpio.conf
# ---------------------------------------------------------------------------
MKINITCPIO="/etc/mkinitcpio.conf"
if grep -q "vfio_pci" "$MKINITCPIO"; then
  echo "    VFIO modules already present in mkinitcpio.conf"
else
  echo "    Adding VFIO modules to mkinitcpio.conf..."
  sudo cp "$MKINITCPIO" "${MKINITCPIO}.bak"
  if grep -q "^MODULES=()" "$MKINITCPIO"; then
    sudo sed -i 's/^MODULES=()/MODULES=(vfio_pci vfio vfio_iommu_type1)/' "$MKINITCPIO"
  else
    sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 vfio_pci vfio vfio_iommu_type1)/' "$MKINITCPIO"
  fi
  NEEDS_MKINITCPIO=true
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
  echo 'iommu=pt vfio-pci.ids=10de:249d,10de:228b' | sudo tee "$CMDLINE_FILE" > /dev/null
  echo "    Created $CMDLINE_FILE"
  NEEDS_MKINITCPIO=true
fi

# ---------------------------------------------------------------------------
# 3. Regenerate initramfs (only if something changed)
# ---------------------------------------------------------------------------
if $NEEDS_MKINITCPIO; then
  echo ">>> Regenerating initramfs..."
  yes | sudo mkinitcpio -P 2>&1
else
  echo ">>> No changes to initramfs config, skipping mkinitcpio"
fi

echo ">>> VFIO setup complete. Reboot required for changes to take effect."

# ---------------------------------------------------------------------------
# 4. Add VFIO kernel entry in Limine (if not already present)
# ---------------------------------------------------------------------------
LIMINE_CONF="/boot/limine.conf"
if sudo grep -qm1 'linux-cachyos-vfio' "$LIMINE_CONF" 2>/dev/null; then
  echo "    VFIO Limine entry already exists"
else
  echo "    Adding VFIO kernel entry to Limine..."

  # Check if helper script exists
  if [ -f "$SCRIPT_DIR/dot_local/bin/.add-vfio-entry" ]; then
    sudo /usr/bin/python3 "$SCRIPT_DIR/dot_local/bin/.add-vfio-entry" "$LIMINE_CONF"
    echo "    VFIO Limine entry added"
  else
    echo "    WARNING: .add-vfio-entry helper not found, skipping Limine entry"
  fi
fi
