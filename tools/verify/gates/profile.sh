#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/profile.sh — PIPELINE PROFILES (PHASE 10)
# Definiuje 4 profile pipeline i mapuje gate'y na profile.
# RELEASE jest nadzbiorem — zawiera wszystkie gate'y.
#
# Profile:
#   LOCAL_FAST — pre-commit, <5-10s, oczywiste błędy (security, structure, performance, git-hooks)
#   PRE_PUSH   — pre-push, pełna certyfikacja lokalnego drzewa
#   CI         — CI, niezależna weryfikacja (dodaje CI gate)
#   RELEASE    — pełna certyfikacja release (nadzbiór wszystkich)
#
# Użycie:
#   profile.sh [PROFILE]   — wypisuje gate'y dla profilu
#   profile.sh list        — wypisuje wszystkie profile i ich gate'y
#   profile.sh count        — wypisuje liczbę gate'ów per profil
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

GATES_DIR="./tools/verify/gates"
REGISTRY="$GATES_DIR/registry.sh"

# ── Wczytaj registry ────────────────────────────────────────
if [ ! -f "$REGISTRY" ]; then
  fail "PROFILE registry" BLOCKING "Brak registry.sh."
  verify_module_exit
fi
# shellcheck source=registry.sh
. "$REGISTRY"

ACTION="${1:-list}"

case "$ACTION" in
  list)
    say "=== PIPELINE PROFILES ==="
    for profile in LOCAL_FAST PRE_PUSH CI RELEASE; do
      gates="$(registry_gates_for_profile "$profile")"
      count="$(printf '%s' "$gates" | grep -c . || true)"
      say ""
      say "── $profile ($count gate'ów) ──"
      for g in $gates; do
        say "  $g  $(registry_field "$g" 3)"
      done
    done
    ;;
  count)
    say "=== LICZBA GATE'ÓW PER PROFIL ==="
    for profile in LOCAL_FAST PRE_PUSH CI RELEASE; do
      gates="$(registry_gates_for_profile "$profile")"
      count="$(printf '%s' "$gates" | grep -c . || true)"
      say "  $profile: $count"
    done
    ;;
  *)
    # Domyślnie: wypisz gate'y dla podanego profilu.
    gates="$(registry_gates_for_profile "$ACTION")"
    if [ -z "$gates" ]; then
      fail "PROFILE $ACTION" BLOCKING "Nieznany profil lub brak gate'ów."
      verify_module_exit
    fi
    for g in $gates; do
      say "$g"
    done
    ;;
esac

verify_module_exit
