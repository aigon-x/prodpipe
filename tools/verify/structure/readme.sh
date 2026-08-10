#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# structure/readme.sh — AIGON Production Platform — Repository Certification Engine
# Moduł: STRUCTURE — README CONTRACTS
# Weryfikuje, że każdy katalog ma README z 12 sekcjami.
#
# Kontrakt README (12 sekcji):
#   1. Purpose  2. Owner  3. Source of Truth  4. Contains
#   5. Does Not Contain  6. Dependencies  7. Consumers
#   8. Synchronization  9. Lifecycle  10. Security
#   11. Recovery  12. Drift Detection
#
# Checki:
#   STR-001  Every directory has README.md
#   STR-002  README has all 12 sections
#   STR-003  README has Status marker (informational)
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== STRUCTURE — README CONTRACTS ==="

SECTIONS=(
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

# STR-001 Every directory has README.md
# Root README.md jest wyłączony (platform overview).
#
# Katalogi STRUKTURALNE (wykluczone ze skanera) — infrastruktura/konfiguracja/
# dane generowane/testy, gdzie kontrakt README (12 sekcji) nie ma zastosowania:
#   .git-hooks, .github, .github/workflows  — infrastruktura git/CI
#   system/control-plane/state/{migrations,data,tests} — migracje SQL, dane runtime, testy
#   config/generated, docs/generated, docs/generated/reconciliation — artefakty generowane
#   docs/git — dokumentacja git (nie moduł domenowy)
#   .tools — narzędzia pomocnicze
# Katalogi DOMENOWE (tools/security, tools/verify/*) MUSZĄ mieć README.
EXCLUDE_STRUCTURAL=(
  "./.git-hooks"
  "./.github"
  "./.github/workflows"
  "./system/control-plane/state/migrations"
  "./system/control-plane/state/data"
  "./system/control-plane/state/tests"
  "./config/generated"
  "./docs/generated"
  "./docs/generated/reconciliation"
  "./docs/git"
  "./.tools"
)

MISSING_README=0
MISSING_DIRS=""
while IFS= read -r d; do
  # Pomiń .git i katalogi bez README (root jest wyłączony)
  [ "$d" = "." ] && continue
  # Pomiń katalogi strukturalne (wykluczone ze skanera)
  skip=0
  for ex in "${EXCLUDE_STRUCTURAL[@]}"; do
    [ "$d" = "$ex" ] && { skip=1; break; }
  done
  [ "$skip" -eq 1 ] && continue
  if [ ! -f "$d/README.md" ]; then
    MISSING_README=$((MISSING_README+1))
    MISSING_DIRS="$MISSING_DIRS $d"
  fi
done < <(find . -type d -not -path './.git/*' -not -path './.git' 2>/dev/null)

if [ "$MISSING_README" -eq 0 ]; then
  pass "STR-001 Every directory has README.md"
else
  fail "STR-001 Every directory has README.md" BLOCKING "Katalogi bez README: $MISSING_DIRS"
fi

# STR-002 README has all 12 sections
MISSING_SECTIONS=0
MISSING_DETAIL=""
while IFS= read -r f; do
  # Root README.md jest wyłączony (platform overview)
  [ "$f" = "./README.md" ] && continue
  for sec in "${SECTIONS[@]}"; do
    if ! grep -qF "$sec" "$f"; then
      MISSING_SECTIONS=$((MISSING_SECTIONS+1))
      MISSING_DETAIL="$MISSING_DETAIL [$sec] in $f"
    fi
  done
done < <(find . -name README.md -not -path './.git/*' 2>/dev/null)

if [ "$MISSING_SECTIONS" -eq 0 ]; then
  pass "STR-002 README has all 12 sections"
else
  fail "STR-002 README has all 12 sections" BLOCKING "Brakujące sekcje: $MISSING_DETAIL"
fi

# STR-003 README has Status marker (informational)
NO_STATUS=0
while IFS= read -r f; do
  [ "$f" = "./README.md" ] && continue
  if ! grep -qE 'STATUS:|Status:' "$f"; then
    NO_STATUS=$((NO_STATUS+1))
  fi
done < <(find . -name README.md -not -path './.git/*' 2>/dev/null)

if [ "$NO_STATUS" -eq 0 ]; then
  pass "STR-003 README has Status marker"
else
  info "STR-003 README has Status marker" "$NO_STATUS README bez markera Status."
fi

verify_module_exit
