#!/bin/bash
# =============================================================================
# run_once_03-nbfc.sh
# Run once by chezmoi (re-runs if this file changes)
# Build & install nbfc-linux and nbfc-qt from iswad-lab forks
# Idempotent: safe to re-run, skips if already built and configured
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

# --- Check if nbfc-linux is already installed from iswad-lab fork ---------------
NBFB_BIN="/usr/bin/nbfc-linux"
NBFB_BUILT=false

if [ -f "$NBFB_BIN" ] && strings "$NBFB_BIN" 2>/dev/null | grep -q "iswad-lab"; then
  log_skip "nbfc-linux already installed (iswad-lab fork)"
else
  log_info "Building nbfc-linux from iswad-lab/nbfc-linux..."
  NBFB_BUILT=true

  WORKDIR=$(mktemp -d)
  trap 'rm -rf "$WORKDIR"' EXIT

  # Clean any previous manual install
  sudo rm -f /usr/bin/nbfc-linux 2>/dev/null || true

  git clone --depth=1 https://github.com/iswad-lab/nbfc-linux "$WORKDIR/nbfc-linux"
  cd "$WORKDIR/nbfc-linux"
  ./autogen.sh > /dev/null || log_fatal "autogen.sh failed"
  ./configure --prefix=/usr --sysconfdir=/etc --bindir=/usr/bin > /dev/null || log_fatal "configure failed"
  make 2>&1 | tail -5 || log_fatal "make failed"
  sudo make install > /dev/null 2>&1
  cd /
fi

# --- Check if nbfc-qt is already installed -------------------------------------
NBFB_QT_BIN="/usr/bin/nbfc-qt"
if [ -f "$NBFB_QT_BIN" ]; then
  log_skip "nbfc-qt already installed"
else
  log_info "Building nbfc-qt from iswad-lab/nbfc-qt..."
  NBFB_BUILT=true

  if [ -z "${WORKDIR:-}" ]; then
    WORKDIR=$(mktemp -d)
    trap 'rm -rf "$WORKDIR"' EXIT
  fi

  git clone --depth=1 https://github.com/iswad-lab/nbfc-qt "$WORKDIR/nbfc-qt"
  cd "$WORKDIR/nbfc-qt"
  make QT_VERSION=6 > /dev/null 2>&1
  sudo make install > /dev/null 2>&1
  cd /
fi

# --- Lock nbfc packages in IgnorePkg (idempotent) -------------------------------
if grep -q "^IgnorePkg" /etc/pacman.conf; then
  for pkg in nbfc-linux nbfc-qt; do
    if ! grep -q "$pkg" /etc/pacman.conf; then
      log_info "Adding $pkg to IgnorePkg..."
      sudo sed -i "s/^IgnorePkg\s*=\s*/IgnorePkg = $pkg /" /etc/pacman.conf
    fi
  done
else
  log_info "Adding IgnorePkg = nbfc-linux nbfc-qt..."
  sudo sed -i 's/^#IgnorePkg.*/IgnorePkg = nbfc-linux nbfc-qt/' /etc/pacman.conf
fi

# --- Deploy fan profile (idempotent) -------------------------------------------
FAN_PROFILE="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}/iswad-nbfc.json"

if [ ! -f "$FAN_PROFILE" ]; then
  log_fatal "iswad-nbfc.json not found at $FAN_PROFILE"
fi

sudo mkdir -p /usr/share/nbfc/configs

# Only copy if content differs
if [ -f /usr/share/nbfc/configs/iswad-nbfc.json ]; then
  if ! cmp -s "$FAN_PROFILE" /usr/share/nbfc/configs/iswad-nbfc.json; then
    log_info "Updating fan profile..."
    sudo cp "$FAN_PROFILE" /usr/share/nbfc/configs/
  else
    log_pass "Fan profile already up to date"
  fi
else
  log_info "Deploying fan profile..."
  sudo cp "$FAN_PROFILE" /usr/share/nbfc/configs/
fi

# --- Write service config (idempotent) -----------------------------------------
sudo mkdir -p /etc/nbfc
NBFB_CONFIG="/etc/nbfc/nbfc.json"
CURRENT_CONFIG='{"SelectedConfigId": "iswad-nbfc"}'
if [ -f "$NBFB_CONFIG" ]; then
  if [ "$(cat "$NBFB_CONFIG")" != "$CURRENT_CONFIG" ]; then
    log_info "Updating NBFC service config..."
    echo "$CURRENT_CONFIG" | sudo tee "$NBFB_CONFIG" > /dev/null
  fi
else
  log_info "Writing NBFC service config..."
  echo "$CURRENT_CONFIG" | sudo tee "$NBFB_CONFIG" > /dev/null
fi

# --- Enable and restart service (only if something changed) ---------------------
if $NBFB_BUILT; then
  log_info "Reloading systemd and restarting NBFC service..."
  sudo systemctl daemon-reload
  sudo systemctl enable nbfc_service.service
  sudo nbfc restart
  log_pass "NBFC setup complete."
else
  log_skip "NBFC already up to date, nothing to do."
fi
