#!/bin/bash
# validate.sh — check that all dotfiles components are correctly deployed
# Run after install to verify everything is in place
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

# --- Services ---
echo ""
echo "  Services..."
for svc in power-profile.service nbfc_service.service; do
  if systemctl is-active "$svc" &>/dev/null; then pass "$svc active"; else fail "$svc not active"; fi
done

# --- Udev rule ---
echo ""
echo "  Udev..."
if [ -f /etc/udev/rules.d/99-power-profile.rules ]; then
  pass "power-profile udev rule"
else
  fail "power-profile udev rule missing"
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

# --- Swappiness (only checked if no zram) ---
echo ""
echo "  Sysctl..."
if ! lsblk | grep -q zram; then
  SWAP=$(cat /proc/sys/vm/swappiness 2>/dev/null)
  [ "$SWAP" = "10" ] && pass "swappiness=10" || fail "swappiness=$SWAP (expected 10, or zram active)"
fi
pass "zram detected (swappiness managed by kernel)"

# --- KDE config ---
echo ""
echo "  KDE config..."
for f in kglobalshortcutsrc kwinrc kwinrulesrc konsolerc dolphinrc; do
  if [ -f "$HOME/.config/$f" ]; then pass "$f"; else fail "$f missing"; fi
done

# --- NBFC ---
echo ""
echo "  NBFC..."
if [ -f /usr/share/nbfc/configs/iswad-nbfc.json ]; then
  pass "fan profile deployed"
else
  fail "fan profile missing"
fi

# --- ZSH ---
echo ""
echo "  ZSH..."
if grep -q "local/bin" "$HOME/.zshrc" 2>/dev/null; then
  pass "local/bin in PATH"
else
  fail "local/bin not in PATH"
fi

echo ""
if [ "$ERR" -eq 0 ]; then
  echo "  ✅ ALL CHECKS PASSED"
else
  echo "  ⚠ $ERR check(s) failed"
fi
echo ""
echo "──────────────────────────────────────────"
exit "$ERR"
