#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/postcondition.sh — GATE-024 POSTCONDITION
# Weryfikuje że każda zarejestrowana akcja ma SPEŁNIONY
# postcondition. "MODEL OUTPUT IS A CLAIM, NOT A FACT."
# Deklaracja nie jest dowodem — silnik WYKONUJE weryfikację
# postcondition po akcji i sprawdza czy stan faktycznie osiągnięty.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-024 POSTCONDITION ==="

STATE_DIR="./system/control-plane/state"
ACTIONS_DIR="$STATE_DIR/actions"

# ── POSTCONDITION-001: każdy postcondition spełniony ────────
# Dla każdej akcji z POSTCONDITION, wykonaj weryfikację:
#   - jeśli postcondition to ścieżka pliku → sprawdź czy istnieje
#   - jeśli to komenda → wykonaj i sprawdź exit code
if [ -d "$ACTIONS_DIR" ]; then
  action_files=$(find "$ACTIONS_DIR" -name '*.sh' -o -name '*.action' 2>/dev/null | wc -l)
  if [ "$action_files" -gt 0 ]; then
    unsatisfied=0
    total=0
    while IFS= read -r f; do
      pc=$(grep -E 'POSTCONDITION=' "$f" 2>/dev/null | head -1 | sed 's/.*POSTCONDITION="\{0,1\}\([^"]*\)"\{0,1\}.*/\1/')
      if [ -n "$pc" ] && [ "$pc" != "-" ]; then
        total=$((total+1))
        # Weryfikacja: jeśli postcondition to ścieżka (zawiera /), sprawdź istnienie
        if echo "$pc" | grep -qE '^\.?\/'; then
          path="${pc#\"}"; path="${path%\"}"
          if [ -e "$path" ]; then
            pass "POSTCONDITION-001 $(basename "$f")" BLOCKING "Postcondition spełniony: $path istnieje."
          else
            unsatisfied=$((unsatisfied+1))
            fail "POSTCONDITION-001 $(basename "$f")" BLOCKING "Postcondition NIESPEŁNIONY: $path nie istnieje."
          fi
        else
          # Postcondition jako komenda — wykonaj i sprawdź exit code
          if eval "$pc" >/dev/null 2>&1; then
            pass "POSTCONDITION-001 $(basename "$f")" BLOCKING "Postcondition spełniony: $pc."
          else
            unsatisfied=$((unsatisfied+1))
            fail "POSTCONDITION-001 $(basename "$f")" BLOCKING "Postcondition NIESPEŁNIONY: $pc."
          fi
        fi
      fi
    done < <(find "$ACTIONS_DIR" -name '*.sh' -o -name '*.action' 2>/dev/null)
    if [ "$total" -eq 0 ]; then
      info "POSTCONDITION-001 postconditions spełnione" "Brak akcji z postcondition do weryfikacji."
    elif [ "$unsatisfied" -eq 0 ]; then
      pass "POSTCONDITION-001 postconditions spełnione" BLOCKING "$total postconditions, wszystkie spełnione."
    else
      fail "POSTCONDITION-001 postconditions spełnione" BLOCKING "$unsatisfied/$total postconditions NIESPEŁNIONYCH."
    fi
  else
    info "POSTCONDITION-001 postconditions spełnione" "Brak zarejestrowanych akcji."
  fi
else
  info "POSTCONDITION-001 postconditions spełnione" "Brak katalogu akcji — brak postconditions do weryfikacji."
fi

# ── POSTCONDITION-002: brak akcji z pustym postcondition ────
# Akcja bez postcondition to "claim without proof" — niedozwolone.
if [ -d "$ACTIONS_DIR" ]; then
  action_files=$(find "$ACTIONS_DIR" -name '*.sh' -o -name '*.action' 2>/dev/null | wc -l)
  if [ "$action_files" -gt 0 ]; then
    empty_pc=0
    while IFS= read -r f; do
      if ! grep -qE 'POSTCONDITION=' "$f" 2>/dev/null; then
        empty_pc=$((empty_pc+1))
      fi
    done < <(find "$ACTIONS_DIR" -name '*.sh' -o -name '*.action' 2>/dev/null)
    if [ "$empty_pc" -eq 0 ]; then
      pass "POSTCONDITION-002 brak akcji bez postcondition" BLOCKING "Wszystkie akcje mają postcondition."
    else
      fail "POSTCONDITION-002 brak akcji bez postcondition" BLOCKING "$empty_pc akcji bez postcondition."
    fi
  else
    info "POSTCONDITION-002 brak akcji bez postcondition" "Brak zarejestrowanych akcji."
  fi
fi

verify_module_exit
