#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# debt/debt.sh — AIGON Production Platform — Reconciliation Engine
# Moduł: DEBT RECONCILIATION (warstwa DEBT)
# Klasyfikuje dług jako świadomy (udokumentowany) vs ukryty.
#
# Model 4 warstw:
#   DEBT — dług świadomy vs ukryty
#
# Dług ŚWIADOMY (ALLOWED_LEGACY / ARCHIVED / QUARANTINED):
#   - udokumentowany w kanonie
#   - ma właściciela i termin spłaty
#   - nie wpływa na SoT/wykonanie/bezpieczeństwo
#
# Dług UKRYTY (UNKNOWN / DRIFT):
#   - nieudokumentowany
#   - nie ma właściciela
#   - może wpływać na SoT/wykonanie/bezpieczeństwo
#
# Checki:
#   DEBT-101  Dług świadomy (ALLOWED_LEGACY) — udokumentowany
#   DEBT-102  Dług ukryty (UNKNOWN) — nieudokumentowany
#   DEBT-103  Dług w archive/ — archiwizowany
#   DEBT-104  Dług w quarantine/ — wyizolowany
#   DEBT-105  Dług bez właściciela (OWNERSHIP)
#   DEBT-106  Dług bez terminu spłaty
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"
# shellcheck source=../core/reconcile.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/reconcile.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== DEBT RECONCILIATION (DEBT) ==="

# ── DEBT-101 Dług świadomy (ALLOWED_LEGACY) ─────────────────
say ""
say "--- DEBT: Dług świadomy ---"
# Dług świadomy = elementy w archive/ (archiwizowane) lub oznaczone ALLOWED_LEGACY.
CONSCIOUS=0
if [ -d "./archive" ]; then
  # archive/ to świadomie archiwizowany dług
  CONSCIOUS=$(find ./archive -type f -not -name 'README.md' -not -name '.gitkeep' 2>/dev/null | wc -l)
fi
if [ "$CONSCIOUS" -gt 0 ]; then
  info "DEBT-101 Dług świadomy (ALLOWED_LEGACY)" "$CONSCIOUS elementów w archive/ — świadomie archiwizowane."
else
  pass "DEBT-101 Dług świadomy (ALLOWED_LEGACY)" BLOCKING "Brak długu świadomego."
fi

# ── DEBT-102 Dług ukryty (UNKNOWN) ──────────────────────────
say ""
say "--- DEBT: Dług ukryty ---"
# Dług ukryty = elementy bez klasyfikacji (UNKNOWN).
# Delegowane do debt/scanner.sh (DEBT-014 Status UNKNOWN).
info "DEBT-102 Dług ukryty (UNKNOWN)" "Delegowane do debt/scanner.sh (DEBT-014 Status UNKNOWN)."

# ── DEBT-103 Dług w archive/ ────────────────────────────────
say ""
say "--- DEBT: Archive ---"
if [ -d "./archive" ]; then
  pass "DEBT-103 Dług w archive/" BLOCKING "archive/ istnieje — dług archiwizowany."
else
  info "DEBT-103 Dług w archive/" "Brak archive/."
fi

# ── DEBT-104 Dług w quarantine/ ─────────────────────────────
say ""
say "--- DEBT: Quarantine ---"
if [ -d "./archive/quarantine" ]; then
  qcount=$(find ./archive/quarantine -type f -not -name 'README.md' -not -name '.gitkeep' 2>/dev/null | wc -l)
  if [ "$qcount" -gt 0 ]; then
    info "DEBT-104 Dług w quarantine/" "$qcount elementów w quarantine/ — wyizolowane."
  else
    pass "DEBT-104 Dług w quarantine/" BLOCKING "quarantine/ jest puste."
  fi
else
  info "DEBT-104 Dług w quarantine/" "Brak archive/quarantine/."
fi

# ── DEBT-105 Dług bez właściciela (OWNERSHIP) ───────────────
say ""
say "--- DEBT: Właściciele ---"
if [ -f "./OWNERSHIP.md" ]; then
  # Sprawdź czy OWNERSHIP ma zdefiniowanych właścicieli
  owners=$(grep -cE '@[a-z]+/' ./OWNERSHIP.md 2>/dev/null)
  if [ "$owners" -gt 0 ]; then
    pass "DEBT-105 Dług bez właściciela" BLOCKING "OWNERSHIP.md definiuje $owners właścicieli."
  else
    warn "DEBT-105 Dług bez właściciela" "OWNERSHIP.md nie definiuje właścicieli (@owner/)."
  fi
else
  fail "DEBT-105 Dług bez właściciela" BLOCKING "Brak OWNERSHIP.md."
fi

# ── DEBT-106 Dług bez terminu spłaty ────────────────────────
say ""
say "--- DEBT: Termin spłaty ---"
# Dług bez terminu spłaty = elementy deprecated bez daty.
# Sprawdzamy czy docs z DEPRECATED mają datę.
NODATE=0
while IFS= read -r f; do
  if grep -qiE 'DEPRECATED|deprecated' "$f" 2>/dev/null; then
    if ! grep -qiE '20[0-9]{2}-[0-9]{2}-[0-9]{2}|termin|deadline|spłaty|do:' "$f" 2>/dev/null; then
      NODATE=$((NODATE+1))
    fi
  fi
done < <(repo_files --name '\.md$' | grep -vE '^(tools/verify/|archive/)')

if [ "$NODATE" -eq 0 ]; then
  pass "DEBT-106 Dług bez terminu spłaty" BLOCKING "Brak długu deprecated bez terminu spłaty."
else
  warn "DEBT-106 Dług bez terminu spłaty" "$NODATE plików deprecated bez terminu spłaty."
fi

verify_module_exit
