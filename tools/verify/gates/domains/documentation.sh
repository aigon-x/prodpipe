#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/documentation.sh — GATE-016 DOCUMENTATION
# Weryfikuje że dokumentacja jest zgodna z kontraktem 12-sekcyjnym.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-016 DOCUMENTATION ==="

# ── DOCUMENTATION-001: docs/ istnieje ───────────────────────
if [ -d "./docs" ]; then
  pass "DOCUMENTATION-001 docs/ istnieje" BLOCKING "Katalog docs obecny."
else
  fail "DOCUMENTATION-001 docs/ istnieje" BLOCKING "Brak katalogu docs."
fi

# ── DOCUMENTATION-002: docs/generated/gates istnieje ────────
if [ -d "./docs/generated/gates" ]; then
  pass "DOCUMENTATION-002 docs/generated/gates istnieje" BLOCKING "Katalog docs/generated/gates obecny."
else
  warn "DOCUMENTATION-002 docs/generated/gates istnieje" "Brak docs/generated/gates (generowane przy certyfikacji)."
fi

# ── DOCUMENTATION-003: README ma 12 sekcji kontraktu ────────
REQUIRED_SECTIONS=(
  "## 1. Purpose"
  "## 2. Owner"
  "## 3. Source of Truth"
  "## 4. Contains"
  "## 5. Does Not Contain"
  "## 6. Dependencies"
  "## 7. Consumers"
  "## 8. Synchronization"
  "## 9. Lifecycle"
  "## 10. Security"
  "## 11. Recovery"
  "## 12. Drift Detection"
)
if [ -f "./README.md" ]; then
  MISSING=0
  MISSING_DETAIL=""
  for sec in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -qF "$sec" ./README.md 2>/dev/null; then
      MISSING=$((MISSING+1))
      MISSING_DETAIL="$MISSING_DETAIL [$sec]"
    fi
  done
  if [ "$MISSING" -eq 0 ]; then
    pass "DOCUMENTATION-003 README 12 sekcji" BLOCKING "README.md ma wszystkie 12 sekcji kontraktu."
  else
    warn "DOCUMENTATION-003 README 12 sekcji" "README.md brakuje $MISSING sekcji:$MISSING_DETAIL"
  fi
fi

# ── DOCUMENTATION-004: brak placeholderów w docs ────────────
PLACEHOLDER_COUNT=0
if [ -d "./docs" ]; then
  while IFS= read -r f; do
    if grep -qiE 'placeholder|TODO|brak implementacji' "$f" 2>/dev/null; then
      PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT+1))
    fi
  done < <(find ./docs -name '*.md' 2>/dev/null)
fi
if [ "$PLACEHOLDER_COUNT" -eq 0 ]; then
  pass "DOCUMENTATION-004 brak placeholderów w docs" BLOCKING "Brak placeholderów w docs."
else
  warn "DOCUMENTATION-004 brak placeholderów w docs" "$PLACEHOLDER_COUNT plików docs z placeholderami."
fi

verify_module_exit
