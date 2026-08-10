#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# reconcile/baseline.sh — AIGON Production Platform — Reconciliation Engine
# Moduł: BASELINE DIFF
# Porównuje stan obecny ze stanem z tagu BASELINE-0.1.0.
#
# Model:
#   BASELINE  → stan z tagu BASELINE-0.1.0
#   CURRENT   → stan obecny (working tree)
#   EXPECTED  → zmiany oczekiwane (zgodne z kanonem)
#   UNEXPECTED→ zmiany nieoczekiwane (DRIFT / HISTORY DEBT)
#
# Przykład (port 14008→14009):
#   zmiana 14008→14009: expected found ✅
#   leftover 14008: 🔴 DRIFT
#   14007: 🔴 HISTORICAL DEBT
#
# Checki:
#   BASE-001  Tag BASELINE-0.1.0 istnieje
#   BASE-002  HEAD jest na main
#   BASE-003  Working tree czysty (poza dozwolonymi)
#   BASE-004  Zmiany oczekiwane (EXPECTED)
#   BASE-005  Zmiany nieoczekiwane (UNEXPECTED)
#   BASE-006  Nowe pliki (untracked)
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"
# shellcheck source=../core/reconcile.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/reconcile.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== BASELINE DIFF (BASELINE→CURRENT→EXPECTED→UNEXPECTED) ==="

BASELINE_TAG="BASELINE-0.1.0"

# ── BASE-001 Tag BASELINE-0.1.0 istnieje ────────────────────
say ""
say "--- Baseline tag ---"
if git rev-parse -q --verify "refs/tags/$BASELINE_TAG" >/dev/null 2>&1; then
  pass "BASE-001 Tag $BASELINE_TAG istnieje" BLOCKING
else
  fail "BASE-001 Tag $BASELINE_TAG istnieje" BLOCKING "Brak tagu $BASELINE_TAG."
fi

# ── BASE-002 HEAD jest na main ──────────────────────────────
say ""
say "--- Branch ---"
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$BRANCH" = "main" ]; then
  pass "BASE-002 HEAD na main" BLOCKING "Branch: $BRANCH"
else
  warn "BASE-002 HEAD na main" "Branch: $BRANCH (oczekiwano main)."
fi

# ── BASE-003 Working tree czysty ────────────────────────────
say ""
say "--- Working tree ---"
# Dozwolone zmiany: tools/verify/ (nowy engine), docs/00-foundation/ (nowa foundation)
ALLOWED_PATHS="tools/verify/ docs/00-foundation/"

MODIFIED=$(git status --porcelain 2>/dev/null | grep -E '^ M|^M ' | awk '{print $2}' | head -20)
UNTRACKED=$(git status --porcelain 2>/dev/null | grep -E '^\?\?' | awk '{print $2}' | head -20)

# Zmodyfikowane pliki (poza dozwolonymi)
UNEXPECTED_MOD=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  allowed=0
  for a in $ALLOWED_PATHS; do
    case "$f" in
      "$a"*) allowed=1 ;;
    esac
  done
  if [ "$allowed" -eq 0 ]; then
    UNEXPECTED_MOD="$UNEXPECTED_MOD $f"
  fi
done <<< "$MODIFIED"

if [ -z "$UNEXPECTED_MOD" ]; then
  pass "BASE-003 Working tree czysty" BLOCKING "Brak nieoczekiwanych modyfikacji."
else
  fail "BASE-003 Working tree czysty" BLOCKING "Nieoczekiwane modyfikacje:$UNEXPECTED_MOD"
fi

# ── BASE-004 Zmiany oczekiwane (EXPECTED) ───────────────────
say ""
say "--- Zmiany oczekiwane (EXPECTED) ---"
# tools/verify/ i docs/00-foundation/ to oczekiwane zmiany (nowy engine + foundation)
EXPECTED_FOUND=""
for a in $ALLOWED_PATHS; do
  if [ -e "$a" ]; then
    EXPECTED_FOUND="$EXPECTED_FOUND $a"
  fi
done
if [ -n "$EXPECTED_FOUND" ]; then
  pass "BASE-004 Zmiany oczekiwane (EXPECTED)" BLOCKING "Oczekiwane zmiany: $EXPECTED_FOUND"
else
  info "BASE-004 Zmiany oczekiwane (EXPECTED)" "Brak oczekiwanych zmian."
fi

# ── BASE-005 Zmiany nieoczekiwane (UNEXPECTED) ──────────────
say ""
say "--- Zmiany nieoczekiwane (UNEXPECTED) ---"
if [ -z "$UNEXPECTED_MOD" ]; then
  pass "BASE-005 Zmiany nieoczekiwane (UNEXPECTED)" BLOCKING "Brak nieoczekiwanych zmian."
else
  fail "BASE-005 Zmiany nieoczekiwane (UNEXPECTED)" BLOCKING "$UNEXPECTED_MOD"
fi

# ── BASE-006 Nowe pliki (untracked) ─────────────────────────
say ""
say "--- Nowe pliki (untracked) ---"
UNEXPECTED_NEW=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  allowed=0
  for a in $ALLOWED_PATHS; do
    case "$f" in
      "$a"*) allowed=1 ;;
    esac
  done
  if [ "$allowed" -eq 0 ]; then
    UNEXPECTED_NEW="$UNEXPECTED_NEW $f"
  fi
done <<< "$UNTRACKED"

if [ -z "$UNEXPECTED_NEW" ]; then
  pass "BASE-006 Nowe pliki (untracked)" BLOCKING "Brak nieoczekiwanych nowych plików."
else
  warn "BASE-006 Nowe pliki (untracked)" "Nieoczekiwane nowe pliki:$UNEXPECTED_NEW"
fi

# ── Podsumowanie baseline diff ──────────────────────────────
say ""
recon_baseline_diff \
  "$BASELINE_TAG" \
  "$(git rev-parse --short HEAD 2>/dev/null)" \
  "tools/verify/ docs/00-foundation/" \
  "${UNEXPECTED_MOD:-none}"

verify_module_exit
