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

# ── Katalogi wykluczone z wymogu README z 12 sekcjami ──────
# Katalogi obsługiwane przez własne moduły weryfikacji NIE wymagają
# README z 12 sekcjami (byłby to self-referential loop — np. tools/verify
# nie może wymagać README, które sam weryfikuje). Wykluczamy też katalogi
# pomocnicze/robocze (generated, narzędzia).
#   .git-hooks/, .github/          → git/integrity.sh
#   system/control-plane/state/    → state/ (StateStore)
#   tools/verify/                  → sam engine certyfikacji
#   tools/security/                → security/secrets.sh
#   .tools/                        → narzędzia pomocnicze
#   config/generated/              → generated artifacts (tylko .gitkeep)
# Wzorzec to regex alternatyw (grep -vE), nie lista ze spacjami.
# Każdy katalog dopasowujemy z opcjonalnym końcowym "/" (bo dirname zwraca
# katalog bez "/", np. ".git-hooks", a ścieżka pliku ma "/", np. ".git-hooks/x").
STR_EXCLUDE='^(\.git-hooks/?|\.github/?|system/control-plane/state/?|tools/verify/?|tools/security/?|\.tools/?|config/generated/)'

# STR-001 Every directory has README.md
# Root README.md jest wyłączony (platform overview).
# Katalogi pochodzą z git-tracked plików (nie z find . — to skanowałoby
# nieśledzone artefakty robocze, np. .qwen/, i generowało fałszywe trafienia).
MISSING_README=0
MISSING_DIRS=""
while IFS= read -r d; do
  # Pomiń root i katalogi wykluczone (obsługiwane przez własne moduły)
  [ "$d" = "." ] && continue
  echo "$d" | grep -qE "$STR_EXCLUDE" && continue
  if [ ! -f "$d/README.md" ]; then
    MISSING_README=$((MISSING_README+1))
    MISSING_DIRS="$MISSING_DIRS $d"
  fi
done < <(repo_files | xargs -n1 dirname 2>/dev/null | sort -u)

if [ "$MISSING_README" -eq 0 ]; then
  pass "STR-001 Every directory has README.md"
else
  fail "STR-001 Every directory has README.md" BLOCKING "Katalogi bez README: $MISSING_DIRS"
fi

# STR-002 README has all 12 sections
# git ls-files zwraca ścieżki BEZ prefiksu ./ (np. "README.md", nie "./README.md"),
# więc root README wykluczamy przez dokładne dopasowanie "README.md".
MISSING_SECTIONS=0
MISSING_DETAIL=""
while IFS= read -r f; do
  # Root README.md jest wyłączony (platform overview)
  [ "$f" = "README.md" ] && continue
  # Pomiń README w katalogach wykluczonych
  echo "$f" | grep -qE "$STR_EXCLUDE" && continue
  for sec in "${SECTIONS[@]}"; do
    if ! grep -qF "$sec" "$f"; then
      MISSING_SECTIONS=$((MISSING_SECTIONS+1))
      MISSING_DETAIL="$MISSING_DETAIL [$sec] in $f"
    fi
  done
done < <(repo_files --name 'README\.md$')

if [ "$MISSING_SECTIONS" -eq 0 ]; then
  pass "STR-002 README has all 12 sections"
else
  fail "STR-002 README has all 12 sections" BLOCKING "Brakujące sekcje: $MISSING_DETAIL"
fi

# STR-003 README has Status marker (informational)
NO_STATUS=0
while IFS= read -r f; do
  [ "$f" = "README.md" ] && continue
  echo "$f" | grep -qE "$STR_EXCLUDE" && continue
  if ! grep -qE 'STATUS:|Status:' "$f"; then
    NO_STATUS=$((NO_STATUS+1))
  fi
done < <(repo_files --name 'README\.md$')

if [ "$NO_STATUS" -eq 0 ]; then
  pass "STR-003 README has Status marker"
else
  info "STR-003 README has Status marker" "$NO_STATUS README bez markera Status."
fi

verify_module_exit
