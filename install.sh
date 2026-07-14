#!/bin/bash
# =============================================================================
# install.sh — bootstrap dotfiles from GitHub
# Usage: sh -c "$(curl -fsLS https://raw.githubusercontent.com/iswad-lab/dotfiles/main/install.sh)"
#        ./install.sh               # fresh install (or update if already installed)
#        ./install.sh --dry-run     # check prerequisites only, no install
#        ./install.sh --validate    # force validation even on update
# =============================================================================
set -e

DRY_RUN=false
FORCE_VALIDATE=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --validate) FORCE_VALIDATE=true ;;
  esac
done

if $DRY_RUN; then
  echo ">>> DRY RUN — checking prerequisites only"
  echo ""
fi

# --- Prerequisites check ----------------------------------------------------
echo ">>> Checking prerequisites..."

# Check if running on Arch-based
if [ ! -f /etc/arch-release ] && [ ! -f /etc/cachyos-release ]; then
  echo "ERROR: This install script is for Arch Linux / CachyOS only."
  exit 1
fi
echo "  ✓ Arch / CachyOS detected"

# Check not running as root (makepkg refuses)
if [ "$(id -u)" = "0" ]; then
  echo "ERROR: Do not run as root. Run as a normal user with sudo access."
  exit 1
fi
echo "  ✓ Not root"

# Check internet
if ! ping -c1 archlinux.org &>/dev/null 2>&1; then
  echo "ERROR: No internet connection."
  exit 1
fi
echo "  ✓ Internet OK"

# Auto-detect: fresh install or update?
PARU_MISSING=false
CHEZMOI_MISSING=false
! command -v paru &>/dev/null && PARU_MISSING=true
! command -v chezmoi &>/dev/null && CHEZMOI_MISSING=true

if $PARU_MISSING || $CHEZMOI_MISSING; then
  INSTALL_TYPE="fresh"
  echo "  → Fresh install detected"
else
  INSTALL_TYPE="update"
  echo "  → Update mode (paru + chezmoi already installed)"
fi

if $DRY_RUN; then
  echo ""
  echo ">>> All prerequisites OK. Run without --dry-run to install."
  exit 0
fi

# --- Sudo keepalive (only needed for fresh install) ---------------------------
if [ "$INSTALL_TYPE" = "fresh" ]; then
  echo ">>> Sudo access required (enter password once)..."
  sudo -v
  (sudo -v && while true; do sleep 60; sudo -v; done) &>/dev/null &
  KEEPER=$!
  echo "  ✓ Sudo OK"
fi

# --- paru (skip if already installed) -----------------------------------------
if $PARU_MISSING; then
  echo ">>> Installing paru..."
  sudo pacman -S --needed --noconfirm base-devel git
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
  (cd "$tmpdir/paru" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
else
  echo ">>> paru already installed, skipping"
fi

# --- chezmoi (skip if already installed) --------------------------------------
if $CHEZMOI_MISSING; then
  echo ">>> Installing chezmoi..."
  sudo pacman -S --needed --noconfirm chezmoi
else
  echo ">>> chezmoi already installed, skipping"
fi

# Clear any stale lock (e.g. from interrupted previous install)
rm -f "$HOME/.local/share/chezmoi/.chezmoi.lock"

# --- Apply dotfiles -----------------------------------------------------------
echo ">>> Applying dotfiles from GitHub..."
if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
  chezmoi update --apply 2>/dev/null || chezmoi init --apply https://github.com/iswad-lab/dotfiles
else
  chezmoi init --apply https://github.com/iswad-lab/dotfiles
fi

echo ""
echo ">>> Done. Restart your session to apply all changes."

# Kill sudo timestamp keeper (only if started)
if [ "$INSTALL_TYPE" = "fresh" ]; then
  kill "$KEEPER" 2>/dev/null || true
fi
echo ""

# --- Validation (skip on update unless --validate) ----------------------------
if [ "$INSTALL_TYPE" = "fresh" ] || $FORCE_VALIDATE; then
  echo ">>> Running post-install validation..."
  curl -fsLS "https://raw.githubusercontent.com/iswad-lab/dotfiles/main/validate.sh" | bash
else
  echo ">>> Validation skipped (run with --validate to force)"
fi
