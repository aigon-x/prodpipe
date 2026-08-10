#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/enforcement.sh — ENFORCEMENT (PHASE 6-7)
# Egzekwuje gate'y dla danego profilu pipeline.
# Uruchamia wszystkie gate'y przypisane do profilu i blokuje
# (exit 1) przy jakimkolwiek FAIL BLOCKING.
#
# Użycie:
#   enforcement.sh [PROFILE]
#     PROFILE: LOCAL_FAST | PRE_PUSH | CI | RELEASE (domyślnie LOCAL_FAST)
#
# NO FALSE GREEN: każdy gate uruchamiany jest realnie, exit code
# jest propagowany. Żaden FAIL nie jest maskowany.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

GATES_DIR="./tools/verify/gates"
REGISTRY="$GATES_DIR/registry.sh"
PROFILE="${1:-LOCAL_FAST}"

# ── Wczytaj registry ────────────────────────────────────────
if [ ! -f "$REGISTRY" ]; then
  fail "ENFORCEMENT registry" BLOCKING "Brak registry.sh."
  verify_module_exit
fi
# shellcheck source=registry.sh
. "$REGISTRY"

say "=== ENFORCEMENT (profile: $PROFILE) ==="

# ── Pobierz gate'y dla profilu ──────────────────────────────
GATES="$(registry_gates_for_profile "$PROFILE")"
if [ -z "$GATES" ]; then
  fail "ENFORCEMENT profile" BLOCKING "Profil $PROFILE nie ma przypisanych gate'ów."
  verify_module_exit
fi

say "Egzekwowanie $(printf '%s' "$GATES" | wc -w) gate'ów dla profilu $PROFILE..."

# ── Uruchom każdy gate i agreguj wynik ──────────────────────
GATE_FAIL=0
for gate_id in $GATES; do
  cmd="$(registry_field "$gate_id" 8)"
  status="$(registry_field "$gate_id" 22)"
  # PROPOSED gate'y są zarejestrowane ale nie zaimplementowane —
  # pomijamy je w egzekwowaniu (nie są jeszcze gotowe do egzekucji).
  # To NIE jest shadow gate: są widoczne w registry i raportach jako PROPOSED.
  if [ "$status" = "PROPOSED" ]; then
    say ""
    say "────────────────────────────────────────────────────────────"
    say "GATE: $gate_id ($cmd) — PROPOSED (pominięty, nie zaimplementowany)"
    say "────────────────────────────────────────────────────────────"
    info "enforce $gate_id" "PROPOSED — pominięty w egzekwowaniu."
    continue
  fi
  if [ -z "$cmd" ] || [ ! -f "$cmd" ]; then
    fail "enforce $gate_id" BLOCKING "Brak implementacji: ${cmd:-NONE}"
    GATE_FAIL=$((GATE_FAIL+1))
    continue
  fi
  say ""
  say "────────────────────────────────────────────────────────────"
  say "GATE: $gate_id ($cmd)"
  say "────────────────────────────────────────────────────────────"
  bash "$cmd"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    GATE_FAIL=$((GATE_FAIL+1))
    fail "enforce $gate_id" BLOCKING "Gate zakończył się kodem $rc (oczekiwano 0)."
  fi
done

say ""
say "=== ENFORCEMENT RESULT ==="
if [ "$GATE_FAIL" -eq 0 ]; then
  sayc "ENFORCEMENT: PASS (profil $PROFILE)" "$C_GREEN"
else
  sayc "ENFORCEMENT: FAIL ($GATE_FAIL gate'ów z FAIL)" "$C_RED"
fi

verify_module_exit
