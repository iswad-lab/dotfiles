#!/bin/bash
# =============================================================================
# install.sh — bootstrap dotfiles from GitHub
# Usage: sh -c "$(curl -fsLS https://raw.githubusercontent.com/iswad-lab/dotfiles/main/install.sh)"
#        ./install.sh               # fresh install (or update if already installed)
#        ./install.sh --dry-run     # check prerequisites only, no install
#        ./install.sh --validate    # force validation even on update
# =============================================================================
set -e

# ─── Load logging library from GitHub ───────────────────────────────────────
LIB_URL="https://raw.githubusercontent.com/iswad-lab/dotfiles/main/.lib_logging.sh"
LIB=$(curl -fsLS "$LIB_URL" 2>/dev/null) || true
if [ -n "$LIB" ]; then
  eval "$LIB"
else
  # Fallback: minimal logging
  log_init() { :; }
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
fi

# ─── Parse arguments ───────────────────────────────────────────────────────
DRY_RUN=false
FORCE_VALIDATE=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --validate) FORCE_VALIDATE=true ;;
  esac
done

log_init 8

# ─── Prerequisites ─────────────────────────────────────────────────────────
log_section "Prerequisites"

if $DRY_RUN; then
  log_info "DRY RUN — checking prerequisites only"
fi

if [ ! -f /etc/arch-release ] && [ ! -f /etc/cachyos-release ]; then
  log_fatal "This install script is for Arch Linux / CachyOS only"
fi
log_pass "Arch / CachyOS detected"

if [ "$(id -u)" = "0" ]; then
  log_fatal "Do not run as root. Run as a normal user with sudo access."
fi
log_pass "Not root"

if ! ping -c1 archlinux.org &>/dev/null 2>&1; then
  log_fatal "No internet connection"
fi
log_pass "Internet OK"

# Auto-detect: fresh install or update?
PARU_MISSING=false
CHEZMOI_MISSING=false
! command -v paru &>/dev/null && PARU_MISSING=true
! command -v chezmoi &>/dev/null && CHEZMOI_MISSING=true

if $PARU_MISSING || $CHEZMOI_MISSING; then
  INSTALL_TYPE="fresh"
  log_info "Fresh install detected"
else
  INSTALL_TYPE="update"
  log_info "Update mode (paru + chezmoi already installed)"
fi

if $DRY_RUN; then
  log_pass "All prerequisites OK. Run without --dry-run to install."
  exit 0
fi

# ─── Sudo keepalive ─────────────────────────────────────────────────────────
log_section "Sudo"

if [ "$INSTALL_TYPE" = "fresh" ]; then
  log_info "Sudo access required (enter password once)..."
  sudo -v
  (sudo -v && while true; do sleep 60; sudo -v; done) &>/dev/null &
  KEEPER=$!
  log_pass "Sudo OK"
else
  log_skip "Not needed (update mode)"
fi

# ─── paru ───────────────────────────────────────────────────────────────────
log_section "Package manager"

if $PARU_MISSING; then
  log_info "Installing paru..."
  sudo pacman -S --needed --noconfirm base-devel git
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
  (cd "$tmpdir/paru" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
  log_pass "paru installed"
else
  log_skip "paru already installed"
fi

# ─── chezmoi ────────────────────────────────────────────────────────────────
log_section "chezmoi"

if $CHEZMOI_MISSING; then
  log_info "Installing chezmoi..."
  sudo pacman -S --needed --noconfirm chezmoi
  log_pass "chezmoi installed"
else
  log_skip "chezmoi already installed"
fi

# Clear any stale lock
rm -f "$HOME/.local/share/chezmoi/.chezmoi.lock"

# ─── Apply dotfiles ─────────────────────────────────────────────────────────
log_section "Apply dotfiles"

log_info "Applying dotfiles from GitHub..."
if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
  chezmoi update --apply 2>/dev/null || chezmoi init --apply https://github.com/iswad-lab/dotfiles
else
  chezmoi init --apply https://github.com/iswad-lab/dotfiles
fi
log_pass "Dotfiles applied"

# Kill sudo timestamp keeper
if [ "$INSTALL_TYPE" = "fresh" ]; then
  kill "$KEEPER" 2>/dev/null || true
fi

# ─── Validation ─────────────────────────────────────────────────────────────
log_section "Validation"

if [ "$INSTALL_TYPE" = "fresh" ] || $FORCE_VALIDATE; then
  log_info "Running post-install validation..."
  bash <(curl -fsLS "https://raw.githubusercontent.com/iswad-lab/dotfiles/main/validate.sh")
else
  log_skip "Validation skipped (run with --validate to force)"
  log_info "Restart your session to apply all changes"
fi

# ─── Summary ────────────────────────────────────────────────────────────────
log_summary
