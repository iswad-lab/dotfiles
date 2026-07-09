#!/bin/bash
# test.sh — run pre-deployment checks to validate the dotfiles repo
# This does NOT install anything. It checks the repo itself is healthy.
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; ERR=1; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }

cd "$(dirname "$0")"
ERR=0

echo "── Testing dotfiles ─────────────────────────"
echo ""

# --- Repo checks ---
echo "  Repo..."
if git rev-parse --git-dir &>/dev/null; then
  pass "git repo"
  git diff --quiet HEAD 2>/dev/null && pass "no uncommitted changes" || warn "uncommitted changes"
else
  fail "not a git repo"
fi

# --- All scripts tracked by git ---
echo ""
echo "  Files..."
for f in install.sh validate.sh run_once_*.sh dot_local/bin/*; do
  [ -f "$f" ] && pass "$f" || fail "$f missing"
done

# --- No orphan files ---
echo ""
echo "  Cleanliness..."
for f in $(git ls-files --others --exclude-standard 2>/dev/null); do
  warn "untracked file: $f"
done

# --- install.sh dry-run ---
echo ""
echo "  install.sh..."
if [ -x install.sh ]; then
  pass "executable"
  # Dry-run (skip sudo check since we're testing, not actually installing)
  bash -n install.sh && pass "bash syntax" || fail "bash syntax error"
else
  fail "not executable"
fi

# --- validate.sh syntax ---
echo ""
echo "  validate.sh..."
bash -n validate.sh && pass "bash syntax" || fail "bash syntax error"

# --- Run_once scripts syntax ---
echo ""
echo "  Run_once scripts..."
for f in run_once_*.sh; do
  bash -n "$f" && pass "$f" || fail "$f syntax error"
done

# --- Boot scripts syntax ---
echo ""
echo "  Boot scripts..."
for f in dot_local/bin/limine-boot-* dot_local/bin/power-profile dot_local/bin/backup-data; do
  if head -1 "$f" | grep -q bash; then
    bash -n "$f" && pass "$(basename $f)" || fail "$(basename $f) syntax error"
  fi
done

# --- JSON validity ---
echo ""
echo "  JSON..."
for f in $(find . -name "*.json" -not -path "./.git/*"); do
  jq empty "$f" &>/dev/null && pass "$f" || fail "$f invalid JSON"
done

# --- KDE config files exist ---
echo ""
echo "  KDE config..."
for f in dot_config/kglobalshortcutsrc dot_config/kwinrc dot_config/kwinrulesrc; do
  [ -f "$f" ] && pass "$(basename $f)" || fail "$(basename $f) missing"
done

# --- Plasma widgets ---
echo ""
echo "  KDE widgets..."
for d in dot_local/share/plasma/plasmoids/*; do
  [ -d "$d" ] && pass "$(basename $d)" || fail "$(basename $d) missing"
done

echo ""
if [ "$ERR" -eq 0 ]; then
  echo "  ✅ ALL TESTS PASSED"
else
  echo "  ⚠ $ERR test(s) failed"
fi
echo ""
echo "──────────────────────────────────────────"
exit "$ERR"
