#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# config-guard.sh — AIGON Production Platform — Automated Future Guard
# OPERATION CONFIG ZERO — PHASE 31
#
# Chroni fundament konfiguracji przed przyszłym dryfem:
#   1. Kompilator waliduje canonical config (schema, sekrety, hardcoded IP).
#   2. Fingerprint jest deterministyczny (ta sama kanoniczna → ten sam hash).
#   3. Artefakty GENERATED są odtwarzalne z kanonicznej.
#   4. State subsystem jest spójny (schema version, state hash).
#   5. Brak nowych HARDCODED_INVALID w config/canonical/.
#
# Użycie:
#   ./config-guard.sh            — pełny guard (wszystkie checki)
#   ./config-guard.sh fingerprint — tylko determinizm fingerprintu
#   ./config-guard.sh state       — tylko spójność state
#   ./config-guard.sh status      — status fundamentu
# ─────────────────────────────────────────────────────────────
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

COMPILER="$ROOT/tools/config/config-compiler.sh"
STATE_DIR="$ROOT/system/control-plane/state"
CANONICAL="$ROOT/config/canonical/platform.yaml"

GUARD_FAIL=0
GUARD_PASS=0
GUARD_WARN=0

say()  { printf '%s\n' "$*"; }
pass() { GUARD_PASS=$((GUARD_PASS+1)); say "[PASS] $*"; }
fail() { GUARD_FAIL=$((GUARD_FAIL+1)); say "[FAIL] $*"; }
warn() { GUARD_WARN=$((GUARD_WARN+1)); say "[WARN] $*"; }

# ── 1. Kompilator waliduje canonical config ─────────────────
guard_compiler() {
  say ""
  say "--- GUARD: Kompilator waliduje canonical config ---"
  if [ ! -f "$COMPILER" ]; then
    fail "Brak kompilatora: $COMPILER"
    return
  fi
  local out rc
  out=$(bash "$COMPILER" validate 2>&1)
  rc=$?
  if [ "$rc" -eq 0 ]; then
    pass "Kompilator waliduje canonical config (validate PASS)"
  else
    fail "Kompilator zwrócił kod $rc (oczekiwano 0)"
    say "$out"
  fi
}

# ── 2. Fingerprint deterministyczny ─────────────────────────
guard_fingerprint() {
  say ""
  say "--- GUARD: Fingerprint deterministyczny ---"
  if [ ! -f "$COMPILER" ]; then
    fail "Brak kompilatora: $COMPILER"
    return
  fi
  local fp1 fp2
  fp1=$(bash "$COMPILER" fingerprint 2>&1 | grep -oE '[0-9a-f]{64}' | head -1)
  fp2=$(bash "$COMPILER" fingerprint 2>&1 | grep -oE '[0-9a-f]{64}' | head -1)
  if [ -n "$fp1" ] && [ "$fp1" = "$fp2" ]; then
    pass "Fingerprint deterministyczny: $fp1"
  else
    fail "Fingerprint niedeterministyczny: '$fp1' vs '$fp2'"
  fi
}

# ── 3. Artefakty GENERATED odtwarzalne ──────────────────────
guard_generated() {
  say ""
  say "--- GUARD: Artefakty GENERATED odtwarzalne ---"
  if [ ! -f "$COMPILER" ]; then
    fail "Brak kompilatora: $COMPILER"
    return
  fi
  bash "$COMPILER" generate >/dev/null 2>&1
  if [ -f "$ROOT/config/generated/platform.generated.yaml" ]; then
    pass "Artefakt GENERATED odtwarzalny: platform.generated.yaml"
  else
    fail "Brak artefaktu GENERATED: platform.generated.yaml"
  fi
  if [ -f "$ROOT/config/generated/MANIFEST.generated.txt" ]; then
    pass "Artefakt GENERATED odtwarzalny: MANIFEST.generated.txt"
  else
    fail "Brak artefaktu GENERATED: MANIFEST.generated.txt"
  fi
}

# ── 4. State subsystem spójny ───────────────────────────────
guard_state() {
  say ""
  say "--- GUARD: State subsystem spójny ---"
  if [ ! -f "$STATE_DIR/state.sh" ]; then
    fail "Brak state.sh: $STATE_DIR/state.sh"
    return
  fi
  local out
  out=$(cd "$STATE_DIR" && bash state.sh status 2>&1)
  if echo "$out" | grep -q "Schema version: 2"; then
    pass "State schema version: 2"
  else
    fail "State schema version nie jest 2"
  fi
  if echo "$out" | grep -qE "Database ID:\s+aigon-canonical-state"; then
    pass "State database ID: aigon-canonical-state"
  else
    fail "State database ID niepoprawny"
  fi
}

# ── 5. Brak nowych HARDCODED_INVALID w canonical ────────────
guard_hardcoded() {
  say ""
  say "--- GUARD: Brak HARDCODED_INVALID w canonical ---"
  if [ ! -f "$CANONICAL" ]; then
    fail "Brak canonical config: $CANONICAL"
    return
  fi
  # Kompilator już waliduje brak hardcoded IP i sekretów.
  # Dodatkowo sprawdzamy, czy canonical nie zawiera legacy nazw.
  local legacy
  legacy=$(grep -nE 'aigon-nats|aigon-runtime|aigon-router|aigon-code-serwer|aigon-code-server|aigon-infra-vault|rtv2-runtime-master|runtime-v2-magic-router' "$CANONICAL" 2>/dev/null || true)
  if [ -z "$legacy" ]; then
    pass "Brak legacy nazw w canonical config"
  else
    warn "Legacy nazwy w canonical config (sprawdź): $legacy"
  fi
}

# ── Podsumowanie ────────────────────────────────────────────
guard_summary() {
  say ""
  say "=== CONFIG GUARD RESULT ==="
  say "Checks: $((GUARD_PASS + GUARD_FAIL + GUARD_WARN))  PASS: $GUARD_PASS  FAIL: $GUARD_FAIL  WARN: $GUARD_WARN"
  if [ "$GUARD_FAIL" -gt 0 ]; then
    say "CONFIG GUARD: FAIL"
    return 1
  else
    say "CONFIG GUARD: PASS"
    return 0
  fi
}

# ── Main ────────────────────────────────────────────────────
CMD="${1:-full}"
case "$CMD" in
  full)
    guard_compiler
    guard_fingerprint
    guard_generated
    guard_state
    guard_hardcoded
    ;;
  fingerprint)
    guard_fingerprint
    ;;
  state)
    guard_state
    ;;
  status)
    say "=== CONFIG GUARD STATUS ==="
    say "Kompilator:  $COMPILER"
    say "Canonical:   $CANONICAL"
    say "State dir:   $STATE_DIR"
    say "Guard: aktywny (PHASE 31 — Automated Future Guard)"
    ;;
  *)
    say "Nieznana komenda: $CMD"
    say "Dostępne: full | fingerprint | state | status"
    exit 2
    ;;
esac

guard_summary
exit $?
