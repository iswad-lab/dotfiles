#!/bin/bash
# test.sh — run pre-deployment checks to validate the dotfiles repo
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
  if git diff --quiet HEAD 2>/dev/null; then
    pass "no uncommitted changes"
  else
    warn "uncommitted changes"
  fi
else
  fail "not a git repo"
fi

# --- All scripts tracked by git ---
echo ""
echo "  Files..."
for f in install.sh validate.sh run_once_*.sh dot_local/bin/*; do
  if [ -f "$f" ]; then
    pass "$f"
  else
    fail "$f missing"
  fi
done

# --- No orphan files ---
echo ""
echo "  Cleanliness..."
git ls-files --others --exclude-standard 2>/dev/null | while IFS= read -r f; do
  warn "untracked file: $f"
done
# Reset ERR in case the while subshell didn't propagate

# --- Shell syntax ---
echo ""
echo "  Shell syntax..."
for f in install.sh validate.sh run_once_*.sh; do
  if bash -n "$f"; then
    pass "$f"
  else
    fail "$f syntax error"
  fi
done

for f in dot_local/bin/executable_limine-boot-* dot_local/bin/executable_power-profile dot_local/bin/executable_backup-data; do
  base=$(basename "$f")
  if head -1 "$f" | grep -q bash; then
    if bash -n "$f"; then
      pass "$base"
    else
      fail "$base syntax error"
    fi
  fi
done

# --- JSON validity ---
echo ""
echo "  JSON..."
while IFS= read -r -d '' f; do
  if jq empty "$f" &>/dev/null; then
    pass "$f"
  else
    fail "$f invalid JSON"
  fi
done < <(find . -name "*.json" -not -path "./.git/*" -print0)

# --- KDE config files exist ---
echo ""
echo "  KDE config..."
for f in dot_config/kglobalshortcutsrc dot_config/kwinrc dot_config/kwinrulesrc; do
  base=$(basename "$f")
  if [ -f "$f" ]; then
    pass "$base"
  else
    fail "$base missing"
  fi
done

# --- Plasma widgets ---
echo ""
echo "  KDE widgets..."
for d in dot_local/share/plasma/plasmoids/*; do
  base=$(basename "$d")
  if [ -d "$d" ]; then
    pass "$base"
  else
    fail "$base missing"
  fi
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
