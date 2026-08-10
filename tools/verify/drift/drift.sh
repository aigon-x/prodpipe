#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# drift/drift.sh — AIGON Production Platform — Reconciliation Engine
# Moduł: DRIFT DETECTION (warstwa CANON/DRIFT)
# Wykrywa rozjazd między deklaracją a rzeczywistością:
#   deklaracja vs kod vs Runtime vs deploy vs node.
#
# Model 4 warstw:
#   CANON — zgodność z Source of Truth (kanon)
#   DRIFT — deklaracja vs kod vs Runtime vs deploy vs node
#
# Poziomy:
#   L0 FILESYSTEM — repo/pliki/symlinki/permissions/generated
#   L1 REPOSITORY — git/source/config/docs/deps/Docker
#   L2 RUNTIME    — services/registry/ports/networks/telemetry/agents
#   L3 CLUSTER    — node↔node/images/versions/ABI/SoT/config/identity
#
# Checki:
#   DRIFT-001  Root README jest platform overview (wyłączony z kontraktu)
#   DRIFT-002  Sekcje README: REQUIRED_MISSING/DUPLICATE/WRONG_ORDER (FAIL)
#   DRIFT-003  Sekcje README: OPTIONAL_ALLOWED (PASS)
#   DRIFT-004  Sekcje README: UNKNOWN_SECTION (WARN/DRIFT)
#   DRIFT-005  SoT STATUS: UNDEFINED (wymaga decyzji)
#   DRIFT-006  OWNERSHIP STATUS: UNDEFINED (wymaga decyzji)
#   DRIFT-007  Shadow system: duplikacja logiki weryfikacji
#   DRIFT-008  CI placeholders (niezaimplementowane workflow)
#   DRIFT-009  pre-push blokuje main bez remote (konflikt z commit+push)
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"
# shellcheck source=../core/reconcile.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/reconcile.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== DRIFT DETECTION (CANON/DRIFT) ==="

# ── README CONTRACT v1 ──────────────────────────────────────
# Required sections (12): 1.Purpose 2.Owner 3.Source of Truth
#   4.Contains 5.Does Not Contain 6.Dependencies 7.Consumers
#   8.Synchronization 9.Lifecycle 10.Security 11.Recovery
#   12.Drift Detection
# Optional sections: Examples
# Root README.md jest WYŁĄCZONY (platform overview).
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
OPTIONAL_SECTIONS=(
  "## Examples"
)

# ── Katalogi wykluczone z kontraktu README ──────────────────
# Katalogi obsługiwane przez własne moduły weryfikacji NIE wymagają
# README z 12 sekcjami (self-referential loop — np. tools/verify nie może
# wymagać README, które sam weryfikuje). Wykluczamy też katalogi
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
DRIFT_EXCLUDE='^(\.git-hooks/?|\.github/?|system/control-plane/state/?|tools/verify/?|tools/security/?|\.tools/?|config/generated/)'

# ── DRIFT-001 Root README jest platform overview ────────────
say ""
say "--- L1 REPOSITORY: README CONTRACT ---"
if [ -f "./README.md" ]; then
  pass "DRIFT-001 Root README jest platform overview" BLOCKING "Root README.md wyłączony z kontraktu 12 sekcji."
else
  fail "DRIFT-001 Root README jest platform overview" BLOCKING "Brak root README.md."
fi

# ── DRIFT-002/003/004 Sekcje README ─────────────────────────
# Dla każdego README (poza root) sprawdzamy:
#   REQUIRED_MISSING   → FAIL
#   REQUIRED_DUPLICATE → FAIL
#   REQUIRED_WRONG_ORDER → FAIL
#   OPTIONAL_ALLOWED   → PASS
#   UNKNOWN_SECTION    → WARN/DRIFT
TOTAL_README=0
MISSING_COUNT=0
DUPLICATE_COUNT=0
WRONG_ORDER_COUNT=0
UNKNOWN_COUNT=0
MISSING_DETAIL=""
DUPLICATE_DETAIL=""
WRONG_ORDER_DETAIL=""
UNKNOWN_DETAIL=""

while IFS= read -r f; do
  # Root README.md jest wyłączony (platform overview).
  # git ls-files zwraca ścieżki BEZ prefiksu ./ (np. "README.md", nie "./README.md").
  [ "$f" = "README.md" ] && continue
  # Pomiń README w katalogach wykluczonych (obsługiwane przez własne moduły)
  echo "$f" | grep -qE "$DRIFT_EXCLUDE" && continue
  TOTAL_README=$((TOTAL_README+1))

  # REQUIRED_MISSING
  local_missing=""
  for sec in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -qF "$sec" "$f"; then
      local_missing="$local_missing [$sec]"
    fi
  done
  if [ -n "$local_missing" ]; then
    MISSING_COUNT=$((MISSING_COUNT+1))
    MISSING_DETAIL="$MISSING_DETAIL $f:$local_missing"
  fi

  # REQUIRED_DUPLICATE
  local_dup=""
  for sec in "${REQUIRED_SECTIONS[@]}"; do
    count=$(grep -cF "$sec" "$f")
    if [ "$count" -gt 1 ]; then
      local_dup="$local_dup [$sec x$count]"
    fi
  done
  if [ -n "$local_dup" ]; then
    DUPLICATE_COUNT=$((DUPLICATE_COUNT+1))
    DUPLICATE_DETAIL="$DUPLICATE_DETAIL $f:$local_dup"
  fi

  # REQUIRED_WRONG_ORDER — sprawdzamy kolejność sekcji 1..12
  local_order=""
  prev_line=0
  for sec in "${REQUIRED_SECTIONS[@]}"; do
    line=$(grep -nF "$sec" "$f" | head -1 | cut -d: -f1)
    if [ -n "$line" ] && [ "$line" -lt "$prev_line" ]; then
      local_order="$local_order [$sec]"
    fi
    [ -n "$line" ] && prev_line="$line"
  done
  if [ -n "$local_order" ]; then
    WRONG_ORDER_COUNT=$((WRONG_ORDER_COUNT+1))
    WRONG_ORDER_DETAIL="$WRONG_ORDER_DETAIL $f:$local_order"
  fi

  # UNKNOWN_SECTION — sekcje ## które nie są required ani optional
  local_unknown=""
  while IFS= read -r hdr; do
    known=0
    for sec in "${REQUIRED_SECTIONS[@]}" "${OPTIONAL_SECTIONS[@]}"; do
      if [ "$hdr" = "$sec" ]; then known=1; break; fi
    done
    if [ "$known" -eq 0 ]; then
      local_unknown="$local_unknown [$hdr]"
    fi
  done < <(grep -E '^## ' "$f" 2>/dev/null)
  if [ -n "$local_unknown" ]; then
    UNKNOWN_COUNT=$((UNKNOWN_COUNT+1))
    UNKNOWN_DETAIL="$UNKNOWN_DETAIL $f:$local_unknown"
  fi
done < <(repo_files --name 'README\.md$')

if [ "$MISSING_COUNT" -eq 0 ]; then
  pass "DRIFT-002 README REQUIRED_MISSING" BLOCKING "Wszystkie README mają 12 wymaganych sekcji."
else
  fail "DRIFT-002 README REQUIRED_MISSING" BLOCKING "$MISSING_COUNT README bez wymaganych sekcji: $MISSING_DETAIL"
fi

if [ "$DUPLICATE_COUNT" -eq 0 ]; then
  pass "DRIFT-002 README REQUIRED_DUPLICATE" BLOCKING "Brak zduplikowanych sekcji."
else
  fail "DRIFT-002 README REQUIRED_DUPLICATE" BLOCKING "$DUPLICATE_COUNT README z duplikatami: $DUPLICATE_DETAIL"
fi

if [ "$WRONG_ORDER_COUNT" -eq 0 ]; then
  pass "DRIFT-002 README REQUIRED_WRONG_ORDER" BLOCKING "Kolejność sekcji 1-12 poprawna."
else
  fail "DRIFT-002 README REQUIRED_WRONG_ORDER" BLOCKING "$WRONG_ORDER_COUNT README ze złą kolejnością: $WRONG_ORDER_DETAIL"
fi

# OPTIONAL_ALLOWED — "## Examples" jest dozwolone (PASS)
if [ "$TOTAL_README" -gt 0 ]; then
  pass "DRIFT-003 README OPTIONAL_ALLOWED" BLOCKING "Sekcje opcjonalne (Examples) są dozwolone."
else
  info "DRIFT-003 README OPTIONAL_ALLOWED" "Brak README do sprawdzenia."
fi

if [ "$UNKNOWN_COUNT" -eq 0 ]; then
  pass "DRIFT-004 README UNKNOWN_SECTION" BLOCKING "Brak nieznanych sekcji."
else
  warn "DRIFT-004 README UNKNOWN_SECTION" "$UNKNOWN_COUNT README z nieznanymi sekcjami: $UNKNOWN_DETAIL"
fi

# ── DRIFT-005 SoT STATUS: UNDEFINED ─────────────────────────
say ""
say "--- L1 REPOSITORY: Source of Truth ---"
if [ -f "./SOURCE-OF-TRUTH.md" ]; then
  sot_status=$(grep -E 'STATUS:' ./SOURCE-OF-TRUTH.md | head -1 | sed 's/.*STATUS:[[:space:]]*//')
  if [ -z "$sot_status" ] || [ "$sot_status" = "UNDEFINED" ]; then
    warn "DRIFT-005 SoT STATUS: UNDEFINED" "SOURCE-OF-TRUTH.md ma STATUS: $sot_status — wymaga świadomej decyzji."
  else
    pass "DRIFT-005 SoT STATUS zdefiniowany" BLOCKING "SOURCE-OF-TRUTH.md STATUS: $sot_status"
  fi
else
  fail "DRIFT-005 SoT STATUS" BLOCKING "Brak SOURCE-OF-TRUTH.md."
fi

# ── DRIFT-006 OWNERSHIP STATUS: UNDEFINED ───────────────────
if [ -f "./OWNERSHIP.md" ]; then
  own_status=$(grep -E 'STATUS:' ./OWNERSHIP.md | head -1 | sed 's/.*STATUS:[[:space:]]*//')
  if [ -z "$own_status" ] || [ "$own_status" = "UNDEFINED" ]; then
    warn "DRIFT-006 OWNERSHIP STATUS: UNDEFINED" "OWNERSHIP.md ma STATUS: $own_status — wymaga świadomej decyzji."
  else
    pass "DRIFT-006 OWNERSHIP STATUS zdefiniowany" BLOCKING "OWNERSHIP.md STATUS: $own_status"
  fi
else
  fail "DRIFT-006 OWNERSHIP STATUS" BLOCKING "Brak OWNERSHIP.md."
fi

# ── DRIFT-007 Shadow system ─────────────────────────────────
say ""
say "--- L1 REPOSITORY: Shadow system ---"
# Duplikacja logiki weryfikacji: .git-hooks + .github/workflows + tools/verify
SHADOW=0
if [ -d "./.git-hooks" ]; then
  # validate-sot jest shadow system (nie wywoływany przez tools/verify)
  if [ -f "./.git-hooks/validate-sot" ]; then
    SHADOW=$((SHADOW+1))
  fi
fi
if [ "$SHADOW" -gt 0 ]; then
  warn "DRIFT-007 Shadow system" "Znaleziono shadow system (.git-hooks/validate-sot) — duplikacja logiki weryfikacji poza tools/verify."
else
  pass "DRIFT-007 Shadow system" BLOCKING "Brak shadow system."
fi

# ── DRIFT-008 CI placeholders ───────────────────────────────
say ""
say "--- L1 REPOSITORY: CI placeholders ---"
PLACEHOLDER_COUNT=0
PLACEHOLDER_DETAIL=""
if [ -d "./.github/workflows" ]; then
  while IFS= read -r wf; do
    if grep -qiE 'placeholder|brak implementacji|TODO' "$wf"; then
      PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT+1))
      PLACEHOLDER_DETAIL="$PLACEHOLDER_DETAIL $(basename "$wf")"
    fi
  done < <(find ./.github/workflows -name '*.yml' -o -name '*.yaml' 2>/dev/null)
fi
if [ "$PLACEHOLDER_COUNT" -eq 0 ]; then
  pass "DRIFT-008 CI placeholders" BLOCKING "Brak placeholderów w CI."
else
  warn "DRIFT-008 CI placeholders" "$PLACEHOLDER_COUNT workflow z placeholderami: $PLACEHOLDER_DETAIL"
fi

# ── DRIFT-009 pre-push blokuje main bez remote ──────────────
say ""
say "--- L1 REPOSITORY: pre-push / remote ---"
REMOTE=$(git remote 2>/dev/null | head -1)
if [ -z "$REMOTE" ]; then
  if [ -f "./.git-hooks/pre-push" ]; then
    warn "DRIFT-009 pre-push blokuje main bez remote" "Brak remote, a pre-push blokuje push na main — konflikt z regułą commit+push."
  else
    pass "DRIFT-009 pre-push / remote" BLOCKING "Brak remote i brak pre-push."
  fi
else
  pass "DRIFT-009 pre-push / remote" BLOCKING "Remote: $REMOTE"
fi

verify_module_exit
