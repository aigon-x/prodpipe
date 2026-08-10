#!/usr/bin/env bash
# ============================================================================
# test_resilience.sh — NEGATIVE/POSITIVE TESTS for GATE-039 (RESILIENCE)
# ============================================================================
# Testuje że gate resilience (RES-B-01..04) ma wymagane elementy:
#   T1: config/registry.yaml ma sekcję resilience (rto/rpo/restore_drill_max_age/
#       dr_game_day_max_age/floors) -> PASS
#   T2: tools/resilience/restore-drill/restore-drill.sh istnieje i jest wykonywalny
#       -> PASS
#   T3: restore-drill.sh odrzuca --env prod (guard) -> PASS
#   T4: migration 0014_resilience.sql definiuje backup_catalog/
#       resilience_requirements/game_days/spof_findings -> PASS
#   T5: state.sh ma backup/restore/backup-verify/backup-restore-test/
#       backup-retention -> PASS
#   T6: (kontrola negatywna) czysty plik BEZ kluczy resilience -> grep RES-B-01
#       NIE pasuje -> PASS
#
# Użycie: ./test_resilience.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATES_DIR="$(dirname "$SCRIPT_DIR")"
ROOT="$(cd "$GATES_DIR/../../.." && pwd)"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  [PASS] %s\n' "$*"; }
t_fail() { FAIL=$((FAIL+1)); printf '  [FAIL] %s\n' "$*"; }

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "=== TESTS — GATE-039 RESILIENCE ==="

# --- T1: registry.yaml ma sekcję resilience --------------------------------
echo ""
echo "--- T1: config/registry.yaml ma sekcję resilience ---"
REGISTRY_YAML="$ROOT/config/registry.yaml"
if [ -f "$REGISTRY_YAML" ]; then
    if grep -qE '^resilience:' "$REGISTRY_YAML" \
       && grep -qE '^\s+rto:' "$REGISTRY_YAML" \
       && grep -qE '^\s+rpo:' "$REGISTRY_YAML" \
       && grep -qE '^\s+restore_drill_max_age:' "$REGISTRY_YAML" \
       && grep -qE '^\s+dr_game_day_max_age:' "$REGISTRY_YAML" \
       && grep -qE '^\s+floors:' "$REGISTRY_YAML"; then
        t_pass "registry.yaml ma sekcję resilience (rto/rpo/restore_drill_max_age/dr_game_day_max_age/floors)"
    else
        t_fail "registry.yaml NIE ma kompletnej sekcji resilience"
    fi
else
    t_fail "Brak config/registry.yaml"
fi

# --- T2: restore-drill.sh istnieje i jest wykonywalny -----------------------
echo ""
echo "--- T2: restore-drill.sh istnieje i jest wykonywalny ---"
RESTORE_DRILL="$ROOT/tools/resilience/restore-drill/restore-drill.sh"
if [ -f "$RESTORE_DRILL" ] && [ -x "$RESTORE_DRILL" ]; then
    t_pass "restore-drill.sh istnieje i jest wykonywalny"
else
    t_fail "restore-drill.sh brakuje lub nie jest wykonywalny"
fi

# --- T3: restore-drill.sh odrzuca --env prod --------------------------------
echo ""
echo "--- T3: restore-drill.sh odrzuca --env prod ---"
if [ -f "$RESTORE_DRILL" ]; then
    # Guard: skrypt musi zawierać warunek abortujący na prod.
    if grep -qE 'ENV.*!=.*scratch' "$RESTORE_DRILL" \
       || grep -qE '--env prod' "$RESTORE_DRILL" \
       || grep -qE 'prod.*odrzucane|odrzucane.*prod' "$RESTORE_DRILL"; then
        t_pass "restore-drill.sh ma guard odrzucający --env prod"
    else
        t_fail "restore-drill.sh NIE ma guardu odrzucającego --env prod"
    fi
else
    t_fail "restore-drill.sh nie istnieje (nie można sprawdzić guardu)"
fi

# --- T4: migration 0014 definiuje tabele resilience -------------------------
echo ""
echo "--- T4: migration 0014_resilience.sql definiuje tabele ---"
MIGRATION_0014="$ROOT/system/control-plane/state/migrations/0014_resilience.sql"
if [ -f "$MIGRATION_0014" ]; then
    if grep -qE 'CREATE TABLE.*backup_catalog' "$MIGRATION_0014" \
       && grep -qE 'CREATE TABLE.*resilience_requirements' "$MIGRATION_0014" \
       && grep -qE 'CREATE TABLE.*game_days' "$MIGRATION_0014" \
       && grep -qE 'CREATE TABLE.*spof_findings' "$MIGRATION_0014"; then
        t_pass "Migration 0014 definiuje backup_catalog/resilience_requirements/game_days/spof_findings"
    else
        t_fail "Migration 0014 NIE definiuje wszystkich wymaganych tabel"
    fi
else
    t_fail "Brak migration 0014_resilience.sql"
fi

# --- T5: state.sh ma komendy backup/restore/backup-verify/backup-restore-test/backup-retention
echo ""
echo "--- T5: state.sh ma komendy backup/restore/backup-verify/backup-restore-test/backup-retention ---"
STATE_SH="$ROOT/system/control-plane/state/state.sh"
if [ -f "$STATE_SH" ]; then
    if grep -qE 'backup' "$STATE_SH" \
       && grep -qE 'restore' "$STATE_SH" \
       && grep -qE 'backup-verify' "$STATE_SH" \
       && grep -qE 'backup-restore-test' "$STATE_SH" \
       && grep -qE 'backup-retention' "$STATE_SH"; then
        t_pass "state.sh ma backup/restore/backup-verify/backup-restore-test/backup-retention"
    else
        t_fail "state.sh NIE ma wszystkich wymaganych komend backup/restore"
    fi
else
    t_fail "Brak state.sh"
fi

# --- T6: kontrola negatywna — czysty plik bez kluczy resilience -------------
echo ""
echo "--- T6: czysty plik bez kluczy resilience -> grep RES-B-01 NIE pasuje ---"
# RES-B-01 w resilience.sh grepuje '^resilience:' + '^\s+rto:' itd.
# Czysty plik bez tych kluczy musi NIE pasować (brak fałszywego pozytywu).
cat > "$WORK/clean.yaml" <<'EOF'
# zwykły plik konfiguracyjny bez sekcji resilience
app:
  name: demo
  port: 8080
EOF
if grep -qE '^resilience:' "$WORK/clean.yaml" \
   && grep -qE '^\s+rto:' "$WORK/clean.yaml" \
   && grep -qE '^\s+rpo:' "$WORK/clean.yaml" \
   && grep -qE '^\s+restore_drill_max_age:' "$WORK/clean.yaml" \
   && grep -qE '^\s+dr_game_day_max_age:' "$WORK/clean.yaml" \
   && grep -qE '^\s+floors:' "$WORK/clean.yaml"; then
    t_fail "Fałszywy pozytyw — czysty plik pasuje do grep RES-B-01"
else
    t_pass "Czysty plik NIE pasuje do grep RES-B-01 (brak fałszywego pozytywu)"
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
