#!/bin/bash
# =============================================================================
# run_once_07-looking-glass.sh
# Run once by chezmoi (re-runs if this file changes)
# Looking Glass — shared memory + hugepages for GPU passthrough display
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

log_info "Configuring Looking Glass..."

# ---------------------------------------------------------------------------
# 1. Shared memory for Looking Glass (IVSHMEM)
# ---------------------------------------------------------------------------
sudo mkdir -p /etc/tmpfiles.d
echo "f /dev/shm/looking-glass 0660 $USER kvm - 64M" | \
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

log_pass "Looking Glass shared memory and hugepages configured."
log_detail "Install the guest agent (looking-glass-host) inside the VM."
