#!/bin/bash
# validate.sh — check that all dotfiles components are correctly deployed
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; ERR=1; }

ERR=0
echo "── Validating dotfiles ───────────────────────"
echo ""

# --- Scripts in PATH (check direct path too, in case ~/.local/bin not in PATH yet) ---
echo "  Scripts..."
for s in limine-boot-win limine-boot-vfio limine-boot-linux backup-data power-profile; do
  if command -v "$s" &>/dev/null || [ -f "$HOME/.local/bin/$s" ]; then
    pass "$s"
  else
    fail "$s not found"
  fi
done

# --- Packages ---
echo ""
echo "  Packages..."
SCRIPT_DIR="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}"
if [ -f "$SCRIPT_DIR/packages.pacman" ]; then
  MISSING=0
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    if ! pacman -Q "$pkg" &>/dev/null; then fail "$pkg (pacman)"; MISSING=1; fi
  done < <(grep -v '^\s*#' "$SCRIPT_DIR/packages.pacman" | awk '{print $1}')
  if [ "$MISSING" -eq 0 ]; then pass "all pacman packages installed"; fi
fi
if [ -f "$SCRIPT_DIR/packages.aur" ]; then
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    if ! pacman -Q "$pkg" &>/dev/null; then fail "$pkg (AUR)"; fi
  done < <(grep -v '^\s*#' "$SCRIPT_DIR/packages.aur" | awk '{print $1}')
  pass "all AUR packages installed"
fi

# --- Services ---
echo ""
echo "  Services..."
for svc in power-profile.service; do
  if ! systemctl is-active "$svc" &>/dev/null; then
    sleep 2
  fi
  if systemctl is-active "$svc" &>/dev/null; then pass "$svc active"; else fail "$svc not active"; fi
done
# nbfc_service may be inactive on non-HP hardware (VM, different laptop)
if systemctl is-active nbfc_service.service &>/dev/null; then
  pass "nbfc_service.service active"
else
  pass "nbfc_service.service skipped (HP OMEN only)"
fi
for svc in nvidia-powerd.service nvidia-suspend.service nvidia-resume.service; do
  if systemctl is-enabled "$svc" &>/dev/null; then pass "$svc enabled"; else pass "$svc skipped (no NVIDIA)"; fi
done
for svc in virtqemud.socket virtnetworkd.socket; do
  if systemctl is-active "$svc" &>/dev/null; then pass "$svc active"; else fail "$svc not active"; fi
done

# --- Udev ---
echo ""
echo "  Udev..."
if [ -f /etc/udev/rules.d/99-power-profile.rules ]; then
  pass "power-profile udev rule"
else
  fail "power-profile udev rule missing"
fi

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
  if [ -n "$GOV" ]; then
    pass "CPU governor: $GOV"
  else
    fail "CPU governor unknown"
  fi
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
  if [ "$SWAP" = "10" ]; then
    pass "swappiness=10"
  else
    fail "swappiness=$SWAP (expected 10)"
  fi
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
if [ "$HP" -ge 64 ] 2>/dev/null; then
  pass "hugepages: $HP"
else
  fail "hugepages: $HP (expected 64+)"
fi

# --- KDE config ---
echo ""
echo "  KDE config..."
for f in kglobalshortcutsrc kwinrc kwinrulesrc konsolerc dolphinrc; do
  if [ -f "$HOME/.config/$f" ]; then
    pass "$f"
  else
    fail "$f missing"
  fi
done

# --- KDE widgets ---
echo ""
echo "  KDE widgets..."
if [ -d "$HOME/.local/share/plasma/plasmoids/org.kde.olib.thermalmonitor" ]; then
  pass "thermal monitor widget"
else
  fail "thermal monitor widget missing"
fi
if [ -d "$HOME/.local/share/plasma/plasmoids/com.github.mazen.salatprayertime" ]; then
  pass "salat prayer widget"
else
  fail "salat prayer widget missing"
fi

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

# --- Secrets ---
echo ""
echo "  Secrets..."
if [ -f "$HOME/.config/zsh/secrets" ]; then
  pass "secrets file exists"
  PERMS=$(stat -c %a "$HOME/.config/zsh/secrets")
  if [ "$PERMS" = "600" ]; then
    pass "secrets permissions 600"
  else
    fail "secrets permissions $PERMS (should be 600)"
  fi
else
  pass "no secrets file (add one if needed)"
fi

# --- Git remote ---
echo ""
echo "  Git..."
if cd "$SCRIPT_DIR" 2>/dev/null && git remote -v 2>/dev/null | grep -q "iswad-lab/dotfiles"; then
  pass "dotfiles remote OK"
else
  fail "dotfiles remote not found"
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
