#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/action-proof.sh — GATE-023 ACTION-PROOF
# "MODEL OUTPUT IS A CLAIM, NOT A FACT."
# Każde działanie agenta/runtime deklaruje POSTCONDITION
# (oczekiwany stan po akcji). Ten gate weryfikuje że każda
# zarejestrowana akcja MA zadeklarowany postcondition.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-023 ACTION-PROOF ==="

STATE_DIR="./system/control-plane/state"
STATE_DB="$STATE_DIR/data/canonical-state.db"

# ── ACTION-PROOF-001: rejestr akcji istnieje ────────────────
# Akcje deklarują postcondition w system/control-plane/state/actions/
# (katalog rejestru akcji z postcondition).
ACTIONS_DIR="$STATE_DIR/actions"
if [ -d "$ACTIONS_DIR" ]; then
  pass "ACTION-PROOF-001 rejestr akcji" BLOCKING "Katalog akcji obecny."
else
  info "ACTION-PROOF-001 rejestr akcji" "Brak katalogu akcji — tworzę szkielet."
  mkdir -p "$ACTIONS_DIR"
fi

# ── ACTION-PROOF-002: każda akcja ma postcondition ──────────
# Każdy plik akcji w actions/ musi deklarować POSTCONDITION.
if [ -d "$ACTIONS_DIR" ]; then
  action_files=$(find "$ACTIONS_DIR" -name '*.sh' -o -name '*.action' 2>/dev/null | wc -l)
  if [ "$action_files" -gt 0 ]; then
    missing_pc=0
    while IFS= read -r f; do
      if ! grep -qE 'POSTCONDITION=' "$f" 2>/dev/null; then
        missing_pc=$((missing_pc+1))
        warn "ACTION-PROOF-002 akcja $f bez POSTCONDITION"
      fi
    done < <(find "$ACTIONS_DIR" -name '*.sh' -o -name '*.action' 2>/dev/null)
    if [ "$missing_pc" -eq 0 ]; then
      pass "ACTION-PROOF-002 każda akcja ma postcondition" BLOCKING "$action_files akcji, wszystkie z POSTCONDITION."
    else
      fail "ACTION-PROOF-002 każda akcja ma postcondition" BLOCKING "$missing_pc akcji bez POSTCONDITION."
    fi
  else
    info "ACTION-PROOF-002 każda akcja ma postcondition" "Brak zarejestrowanych akcji."
  fi
fi

# ── ACTION-PROOF-003: postcondition jest weryfikowalny ──────
# Postcondition musi być wyrażony jako komenda/ścieżka do sprawdzenia,
# nie jako goła deklaracja słowna.
if [ -d "$ACTIONS_DIR" ]; then
  action_files=$(find "$ACTIONS_DIR" -name '*.sh' -o -name '*.action' 2>/dev/null | wc -l)
  if [ "$action_files" -gt 0 ]; then
    non_verifiable=0
    while IFS= read -r f; do
      pc=$(grep -E 'POSTCONDITION=' "$f" 2>/dev/null | head -1 | sed 's/.*POSTCONDITION="\{0,1\}\([^"]*\)"\{0,1\}.*/\1/')
      if [ -n "$pc" ] && [ "$pc" != "-" ]; then
        # Postcondition weryfikowalny jeśli zawiera ścieżkę/komendę/plik
        if ! echo "$pc" | grep -qE '(\/|test |\[ |grep |ls |sqlite3 |git )'; then
          non_verifiable=$((non_verifiable+1))
          warn "ACTION-PROOF-003 akcja $f: postcondition nie weryfikowalny: $pc"
        fi
      fi
    done < <(find "$ACTIONS_DIR" -name '*.sh' -o -name '*.action' 2>/dev/null)
    if [ "$non_verifiable" -eq 0 ]; then
      pass "ACTION-PROOF-003 postcondition weryfikowalny" BLOCKING "Wszystkie postconditions są weryfikowalne."
    else
      fail "ACTION-PROOF-003 postcondition weryfikowalny" BLOCKING "$non_verifiable postconditions nie weryfikowalnych."
    fi
  else
    info "ACTION-PROOF-003 postcondition weryfikowalny" "Brak zarejestrowanych akcji."
  fi
fi

verify_module_exit
