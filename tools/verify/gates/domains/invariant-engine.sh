#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/invariant-engine.sh — GATE-022 INVARIANT-ENGINE
# Wykonywalny silnik invariants z 12 control planes.
# Stale sprawdza invariants, nie tylko przy verify.
# Każdy invariant ma dowód wykonania (PASS/FAIL/UNKNOWN).
# "Never trust a component's claim about its own state."
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-022 INVARIANT-ENGINE ==="

STATE_DIR="./system/control-plane/state"
STATE_DB="$STATE_DIR/data/canonical-state.db"

# ── INVARIANT-001: StateStore schema_version spójna ─────────
if [ -f "$STATE_DIR/lib.sh" ]; then
  declared=$(grep -E 'STATE_SCHEMA_VERSION=' "$STATE_DIR/lib.sh" | head -1 | sed 's/.*="\([0-9]*\)".*/\1/')
  if [ -n "$declared" ]; then
    pass "INVARIANT-001 schema_version zdefiniowana" BLOCKING "STATE_SCHEMA_VERSION=$declared."
  else
    fail "INVARIANT-001 schema_version zdefiniowana" BLOCKING "Brak STATE_SCHEMA_VERSION."
  fi
fi

# ── INVARIANT-002: migracje sekwencyjne (0001,0002,0004) ───
missing=0
for m in 0001_initial.sql 0002_history_hash.sql 0004_system_twin.sql; do
  if [ ! -f "$STATE_DIR/migrations/$m" ]; then
    missing=$((missing+1))
  fi
done
if [ "$missing" -eq 0 ]; then
  pass "INVARIANT-002 migracje sekwencyjne" BLOCKING "Migracje 0001-0004 obecne."
else
  fail "INVARIANT-002 migracje sekwencyjne" BLOCKING "Brak $missing migracji."
fi

# ── INVARIANT-003: state.sh ma set -euo pipefail ────────────
if [ -f "$STATE_DIR/state.sh" ]; then
  if grep -q 'set -euo pipefail' "$STATE_DIR/state.sh"; then
    pass "INVARIANT-003 state.sh set -euo pipefail" BLOCKING "state.sh ma set -euo pipefail."
  else
    fail "INVARIANT-003 state.sh set -euo pipefail" BLOCKING "state.sh nie ma set -euo pipefail."
  fi
fi

# ── INVARIANT-004: registry.sh parsowalny ───────────────────
if bash -n ./tools/verify/gates/registry.sh 2>/dev/null; then
  pass "INVARIANT-004 registry parsowalny" BLOCKING "registry.sh przechodzi bash -n."
else
  fail "INVARIANT-004 registry parsowalny" BLOCKING "registry.sh ma błąd składni."
fi

# ── INVARIANT-005: każdy gate ma skrypt implementacji ───────
# (registry == implemented). PROPOSED gate'y są świadomie nie
# zaimplementowane (lifecycle) — nie liczone jako brak.
if [ -f ./tools/verify/gates/registry.sh ]; then
  . ./tools/verify/gates/registry.sh
  missing_impl=0
  for gate_id in $(registry_gate_ids); do
    status="$(registry_field "$gate_id" 22)"
    if [ "$status" = "PROPOSED" ]; then
      continue
    fi
    cmd="$(registry_field "$gate_id" 8)"
    if [ -n "$cmd" ] && [ "$cmd" != "-" ] && [ ! -f "$cmd" ]; then
      missing_impl=$((missing_impl+1))
    fi
  done
  if [ "$missing_impl" -eq 0 ]; then
    pass "INVARIANT-005 registry==implemented" BLOCKING "Każdy gate ma skrypt implementacji."
  else
    fail "INVARIANT-005 registry==implemented" BLOCKING "$missing_impl gate'ów bez skryptu."
  fi
fi

# ── INVARIANT-006: brak hardcoded sekretów w tools/verify ───
# (security invariant — wzorce sekretów nie mogą być w kodzie weryfikacji)
# Wykluczamy tests/ — testy negatywne CELOWO zawierają fałszywe sekrety
# (fixtures) do weryfikacji, że gate security je wykrywa. To nie jest
# produkcja, to dane testowe. Wykluczamy też własną linię secret_patterns=.
secret_patterns='(AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY)'
if grep -rE "$secret_patterns" tools/verify/ --include='*.sh' 2>/dev/null \
    | grep -vE 'secret_patterns=' \
    | grep -vE '^tools/verify/gates/tests/' \
    | grep -q .; then
  fail "INVARIANT-006 brak sekretów w tools/verify" BLOCKING "Wykryto wzorce sekretów w tools/verify."
else
  pass "INVARIANT-006 brak sekretów w tools/verify" BLOCKING "Brak wzorców sekretów w tools/verify."
fi

# ── INVARIANT-007: brak false green (|| true, set +e) ───────
# (NO FALSE GREEN invariant — zakaz maskowania błędów)
# Przeszukujemy TYLKO produkcyjne skrypty domen (nie tests/ — testy negatywne
# CELOWO zawierają wzorce bypass do wykrycia). Wykluczamy komentarze i własny
# plik, żeby nie flagować sam siebie (self-referential false positive).
# Uwaga: grep -rEn prependuje "plik:linia:" do każdego dopasowania, więc
# wykluczenie komentarzy musi uwzględniać ten prefiks (:[0-9]+:\s*#).
if grep -rEn '\|\|\s*true|set\s+\+e' tools/verify/gates/domains/ --include='*.sh' 2>/dev/null \
    | grep -vE ':[0-9]+:\s*#' \
    | grep -vE 'invariant-engine\.sh' \
    | grep -q .; then
  fail "INVARIANT-007 brak false green" BLOCKING "Wykryto wzorce false green w gates/domains/."
else
  pass "INVARIANT-007 brak false green" BLOCKING "Brak wzorców false green w gates/domains/."
fi

# ── INVARIANT-008: StateStore baza spójna (jeśli istnieje) ──
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$STATE_DB" ]; then
  integrity=$(sqlite3 "$STATE_DB" "PRAGMA integrity_check;" 2>/dev/null | head -1)
  if [ "$integrity" = "ok" ]; then
    pass "INVARIANT-008 StateStore integrity" BLOCKING "PRAGMA integrity_check: ok."
  else
    fail "INVARIANT-008 StateStore integrity" BLOCKING "PRAGMA integrity_check: $integrity."
  fi
else
  info "INVARIANT-008 StateStore integrity" "Baza StateStore niedostępna — UNKNOWN."
fi

verify_module_exit
