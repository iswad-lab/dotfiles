#!/bin/bash
# =============================================================================
# run_once_06-looking-glass.sh
# Run once by chezmoi (re-runs if this file changes)
# Looking Glass — shared memory + hugepages for GPU passthrough display
# =============================================================================
set -e

echo ">>> Configuring Looking Glass..."

# ---------------------------------------------------------------------------
# 1. Shared memory for Looking Glass (IVSHMEM)
# ---------------------------------------------------------------------------
sudo mkdir -p /etc/tmpfiles.d
echo 'f /dev/shm/looking-glass 0660 iswad kvm - 64M' | \
  sudo tee /etc/tmpfiles.d/looking-glass.conf > /dev/null

# Apply immediately
sudo systemd-tmpfiles --create /etc/tmpfiles.d/looking-glass.conf

# ---------------------------------------------------------------------------
# 2. Hugepages for better performance
# ---------------------------------------------------------------------------
sudo mkdir -p /etc/sysctl.d
echo 'vm.nr_hugepages = 64' | \
  sudo tee /etc/sysctl.d/10-looking-glass.conf > /dev/null

sudo sysctl -w vm.nr_hugepages=64

echo ">>> Looking Glass shared memory and hugepages configured."
echo "    Install the guest agent (looking-glass-host) inside the VM."
