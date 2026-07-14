#!/bin/bash
# =============================================================================
# run_once_03-nbfc.sh
# Run once by chezmoi (re-runs if this file changes)
# Build & install nbfc-linux and nbfc-qt from iswad-lab forks
# Idempotent: safe to re-run, skips if already built and configured
# =============================================================================
set -e

# --- Check if nbfc-linux is already installed from iswad-lab fork ---------------
NBFB_BIN="/usr/bin/nbfc-linux"
NBFB_BUILT=false

if [ -f "$NBFB_BIN" ] && strings "$NBFB_BIN" 2>/dev/null | grep -q "iswad-lab"; then
  echo ">>> nbfc-linux already installed (iswad-lab fork), skipping build"
else
  echo ">>> Building nbfc-linux from iswad-lab/nbfc-linux..."
  NBFB_BUILT=true

  WORKDIR=$(mktemp -d)
  trap 'rm -rf "$WORKDIR"' EXIT

  # Clean any previous manual install
  sudo rm -f /usr/bin/nbfc-linux 2>/dev/null || true

  git clone --depth=1 https://github.com/iswad-lab/nbfc-linux "$WORKDIR/nbfc-linux"
  cd "$WORKDIR/nbfc-linux"
  ./autogen.sh > /dev/null || { echo "ERROR: autogen.sh failed"; exit 1; }
  ./configure --prefix=/usr --sysconfdir=/etc --bindir=/usr/bin > /dev/null || { echo "ERROR: configure failed"; exit 1; }
  make 2>&1 | tail -5 || { echo "ERROR: make failed"; exit 1; }
  sudo make install > /dev/null 2>&1
  cd /
fi

# --- Check if nbfc-qt is already installed -------------------------------------
NBFB_QT_BIN="/usr/bin/nbfc-qt"
if [ -f "$NBFB_QT_BIN" ]; then
  echo ">>> nbfc-qt already installed, skipping build"
else
  echo ">>> Building nbfc-qt from iswad-lab/nbfc-qt..."
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
      echo ">>> Adding $pkg to IgnorePkg..."
      sudo sed -i "s/^IgnorePkg\s*=\s*/IgnorePkg = $pkg /" /etc/pacman.conf
    fi
  done
else
  echo ">>> Adding IgnorePkg = nbfc-linux nbfc-qt..."
  sudo sed -i 's/^#IgnorePkg.*/IgnorePkg = nbfc-linux nbfc-qt/' /etc/pacman.conf
fi

# --- Deploy fan profile (idempotent) -------------------------------------------
FAN_PROFILE="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}/iswad-nbfc.json"

if [ ! -f "$FAN_PROFILE" ]; then
  echo "ERROR: iswad-nbfc.json not found at $FAN_PROFILE"
  exit 1
fi

sudo mkdir -p /usr/share/nbfc/configs

# Only copy if content differs
if [ -f /usr/share/nbfc/configs/iswad-nbfc.json ]; then
  if ! cmp -s "$FAN_PROFILE" /usr/share/nbfc/configs/iswad-nbfc.json; then
    echo ">>> Updating fan profile..."
    sudo cp "$FAN_PROFILE" /usr/share/nbfc/configs/
  else
    echo ">>> Fan profile already up to date"
  fi
else
  echo ">>> Deploying fan profile..."
  sudo cp "$FAN_PROFILE" /usr/share/nbfc/configs/
fi

# --- Write service config (idempotent) -----------------------------------------
sudo mkdir -p /etc/nbfc
NBFB_CONFIG="/etc/nbfc/nbfc.json"
CURRENT_CONFIG='{"SelectedConfigId": "iswad-nbfc"}'
if [ -f "$NBFB_CONFIG" ]; then
  if [ "$(cat "$NBFB_CONFIG")" != "$CURRENT_CONFIG" ]; then
    echo ">>> Updating NBFC service config..."
    echo "$CURRENT_CONFIG" | sudo tee "$NBFB_CONFIG" > /dev/null
  fi
else
  echo ">>> Writing NBFC service config..."
  echo "$CURRENT_CONFIG" | sudo tee "$NBFB_CONFIG" > /dev/null
fi

# --- Enable and restart service (only if something changed) ---------------------
if $NBFB_BUILT; then
  echo ">>> Reloading systemd and restarting NBFC service..."
  sudo systemctl daemon-reload
  sudo systemctl enable nbfc_service.service
  sudo nbfc restart
  echo ">>> NBFC setup complete."
else
  echo ">>> NBFC already up to date, nothing to do."
fi
