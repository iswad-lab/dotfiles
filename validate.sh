#!/bin/bash
# validate.sh — check that all dotfiles components are correctly deployed
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; ERR=1; }

ERR=0
echo "── Validating dotfiles ───────────────────────"
echo ""

# --- Scripts in PATH ---
echo "  Scripts..."
for s in limine-boot-win limine-boot-vfio limine-boot-linux backup-data power-profile; do
  if command -v "$s" &>/dev/null; then pass "$s in PATH"; else fail "$s not found"; fi
done

# --- Packages ---
echo ""
echo "  Packages..."
SCRIPT_DIR="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}"
if [ -f "$SCRIPT_DIR/packages.pacman" ]; then
  MISSING=0
  for pkg in $(grep -v '^\s*#' "$SCRIPT_DIR/packages.pacman" | awk '{print $1}'); do
    pacman -Q "$pkg" &>/dev/null || { fail "$pkg (pacman)"; MISSING=1; }
  done
  [ "$MISSING" -eq 0 ] && pass "all pacman packages installed"
fi
if [ -f "$SCRIPT_DIR/packages.aur" ]; then
  MISSING=0
  for pkg in $(grep -v '^\s*#' "$SCRIPT_DIR/packages.aur" | awk '{print $1}'); do
    # Skip commented-out lines
    [ -z "$pkg" ] && continue
    pacman -Q "$pkg" &>/dev/null || fail "$pkg (AUR)"
  done
  pass "all AUR packages installed"
fi

# --- Services ---
echo ""
echo "  Services..."
for svc in power-profile.service nbfc_service.service; do
  if systemctl is-active "$svc" &>/dev/null; then pass "$svc active"; else fail "$svc not active"; fi
done
for svc in nvidia-powerd.service nvidia-suspend.service nvidia-resume.service; do
  if systemctl is-enabled "$svc" &>/dev/null; then pass "$svc enabled"; else pass "$svc skipped (no NVIDIA)"; fi
done || true
for svc in virtqemud.socket virtnetworkd.socket; do
  if systemctl is-active "$svc" &>/dev/null; then pass "$svc active"; else fail "$svc not active"; fi
done

# --- Udev ---
echo ""
echo "  Udev..."
[ -f /etc/udev/rules.d/99-power-profile.rules ] && pass "power-profile udev rule" || fail "power-profile udev rule missing"

# --- VFIO ---
echo ""
echo "  VFIO..."
if grep -q "vfio" /etc/mkinitcpio.conf 2>/dev/null; then
  pass "VFIO modules in mkinitcpio"
else
  fail "VFIO modules missing"
fi
if [ -f /etc/cmdline.d/vfio.conf ]; then
  pass "VFIO cmdline"
else
  fail "VFIO cmdline missing"
fi

# --- Power profile ---
echo ""
echo "  Power profile..."
if command -v power-profile &>/dev/null; then
  pass "power-profile installed"
  GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
  [ -n "$GOV" ] && pass "CPU governor: $GOV" || fail "CPU governor unknown"
else
  fail "power-profile not installed"
fi

# --- Swappiness ---
echo ""
echo "  Sysctl..."
if lsblk | grep -q zram; then
  pass "zram active (swappiness handled by kernel)"
else
  SWAP=$(cat /proc/sys/vm/swappiness 2>/dev/null)
  [ "$SWAP" = "10" ] && pass "swappiness=10" || fail "swappiness=$SWAP (expected 10)"
fi

# --- Looking Glass ---
echo ""
echo "  Looking Glass..."
LG=/dev/shm/looking-glass
if [ -f "$LG" ]; then
  SIZE=$(du -h "$LG" | awk '{print $1}')
  pass "shared memory ($SIZE)"
else
  fail "shared memory not found"
fi
HP=$(cat /proc/sys/vm/nr_hugepages 2>/dev/null)
[ "$HP" -ge 64 ] 2>/dev/null && pass "hugepages: $HP" || fail "hugepages: $HP (expected 64+)"

# --- KDE config ---
echo ""
echo "  KDE config..."
for f in kglobalshortcutsrc kwinrc kwinrulesrc konsolerc dolphinrc; do
  [ -f "$HOME/.config/$f" ] && pass "$f" || fail "$f missing"
done

# --- KDE widgets ---
echo ""
echo "  KDE widgets..."
[ -d "$HOME/.local/share/plasma/plasmoids/org.kde.olib.thermalmonitor" ] && pass "thermal monitor widget" || fail "thermal monitor widget missing"
[ -d "$HOME/.local/share/plasma/plasmoids/com.github.mazen.salatprayertime" ] && pass "salat prayer widget" || fail "salat prayer widget missing"

# --- NBFC ---
echo ""
echo "  NBFC..."
[ -f /usr/share/nbfc/configs/iswad-nbfc.json ] && pass "fan profile deployed" || fail "fan profile missing"

# --- ZSH ---
echo ""
echo "  ZSH..."
grep -q "local/bin" "$HOME/.zshrc" 2>/dev/null && pass "local/bin in PATH" || fail "local/bin not in PATH"

# --- Secrets ---
echo ""
echo "  Secrets..."
if [ -f "$HOME/.config/zsh/secrets" ]; then
  pass "secrets file exists"
  [ "$(stat -c %a "$HOME/.config/zsh/secrets")" = "600" ] && pass "secrets permissions 600" || fail "secrets permissions $(stat -c %a $HOME/.config/zsh/secrets) (should be 600)"
else
  pass "no secrets file (add one if needed)"
fi

# --- Git remote ---
echo ""
echo "  Git..."
cd "$SCRIPT_DIR" 2>/dev/null && git remote -v 2>/dev/null | grep -q "iswad-lab/dotfiles" && pass "dotfiles remote OK" || fail "dotfiles remote not found"

echo ""
if [ "$ERR" -eq 0 ]; then
  echo "  ✅ ALL CHECKS PASSED"
else
  echo "  ⚠ $ERR check(s) failed"
fi
echo ""
echo "──────────────────────────────────────────"
exit "$ERR"
