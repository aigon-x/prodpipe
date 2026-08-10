#!/usr/bin/env bash
# ============================================================================
# test-config-resolver.sh — Config Plane resolver (config.sh)
# ============================================================================
# Weryfikuje, że:
#   T1: config_resolve zwraca snapshot_id (niepusty)
#   T2: config_get zwraca wartość z snapshotu
#   T3: config_get dla nieznanego klucza = FATAL (exit 2)
#   T4: tighten (powyżej defaultu) przechodzi bez waivera
#   T5: relax (poniżej floora) bez waivera = REJECTED
#   T6: config_simulate wykrywa THRESHOLD_LOOSENED
#   T7: config_exemption_check blokuje klucz niekonfigurowalny
#   T8: brak registry.yaml → config_resolve = exit 2 (fail-closed)
#
# Testy są IZOLOWANE: tworzą własny registry.yaml i własną bazę StateStore
# w katalogu tymczasowym (CONFIG_REGISTRY + VERIFY_STATE_DB), więc nie dotykają
# prawdziwego stanu repo ani równoległej pracy innych subagentów.
#
# Użycie: ./test-config-resolver.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$VERIFY_DIR/../.." && pwd)"
CONFIG_SH="$VERIFY_DIR/core/config.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== CONFIG RESOLVER TESTS ==="

# ── Przygotowanie izolowanego środowiska ───────────────────────────────────
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

# Tymczasowy registry.yaml (L0 defaulty + L1 floors + context rules + waivers).
TEST_REGISTRY="$TEST_DIR/registry.yaml"
cat > "$TEST_REGISTRY" <<'YAML'
gates:
  coverage.min_percent:
    default: 80
    floor: 60
    ratchet: true
    reload: hot
    doc: "Minimalne pokrycie branch coverage"
    owner: platform
    tier: stable
  security.sast.max_critical:
    default: 0
    floor: 0
    ratchet: true
    reload: hot
    doc: "Maksymalna liczba krytycznych znalezisk SAST"
    owner: platform
    tier: stable
  security.sast.max_high:
    default: 5
    floor: 3
    ratchet: true
    reload: hot
    doc: "Maksymalna liczba wysokich znalezisk SAST (max_*: floor = górny limit)"
    owner: platform
    tier: stable
context_rules:
  - match:
      task_type: test
    profile: full
    tighten:
      coverage.min_percent: 90
    relax:
      coverage.min_percent: 70
    compensate:
      coverage.min_percent: security.sast.max_critical
  - id: tier1-critical
    applies_when:
      - { field: tier, op: eq, value: 1 }
    profile: release
    gates:
      security.sast.max_high: { tighten: 1 }
    compensations: []
YAML

# Tymczasowa baza StateStore z tabelami Config Plane (migracja 0007).
TEST_DB="$TEST_DIR/canonical-state.db"
sqlite3 "$TEST_DB" <<'SQL'
CREATE TABLE config_snapshots (
  id INTEGER PRIMARY KEY,
  hash TEXT NOT NULL UNIQUE,
  git_sha TEXT NOT NULL,
  waiver_set_version INTEGER NOT NULL,
  effective_json TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE config_ratchet (
  service_id TEXT NOT NULL,
  key TEXT NOT NULL,
  achieved_value REAL NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (service_id, key)
);
CREATE TABLE config_kill_switches (
  id INTEGER PRIMARY KEY,
  key TEXT NOT NULL, value TEXT NOT NULL,
  activated_by TEXT NOT NULL, reason TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
SQL

# Tymczasowy config_exemptions.yaml (konstytucja niekonfigurowalnych).
TEST_EXEMPTIONS="$TEST_DIR/config_exemptions.yaml"
cat > "$TEST_EXEMPTIONS" <<'YAML'
non_configurable:
  - key: gates.self-001.enabled
  - key: evidence.database.enabled
YAML

# ── Załaduj config.sh z izolowanymi ścieżkami ──────────────────────────────
export CONFIG_REGISTRY="$TEST_REGISTRY"
export CONFIG_EXEMPTIONS="$TEST_EXEMPTIONS"
export VERIFY_STATE_DB="$TEST_DB"
# shellcheck source=core/config.sh
. "$CONFIG_SH"

# ── T1: config_resolve zwraca snapshot_id (niepusty) ───────────────────────
echo ""
echo "--- T1: config_resolve zwraca snapshot_id (niepusty) ---"
SID="$(config_resolve '{"task_type":"default","files":["src/main.go"],"tier":"0"}' "billing-api")"
if [ -n "$SID" ] && [ "$SID" != "0" ]; then
    t_pass "config_resolve zwrócił snapshot_id: $SID"
else
    t_fail "config_resolve zwrócił pusty/zerowy snapshot_id: '$SID'"
fi

# ── T2: config_get zwraca wartość z snapshotu ──────────────────────────────
echo ""
echo "--- T2: config_get zwraca wartość z snapshotu ---"
VAL="$(config_get "$SID" "coverage.min_percent")"
if [ "$VAL" = "80" ]; then
    t_pass "config_get coverage.min_percent = $VAL (default L0)"
else
    t_fail "config_get coverage.min_percent = '$VAL' (oczekiwano '80')"
fi

# ── T3: config_get dla nieznanego klucza = FATAL (exit 2) ──────────────────
echo ""
echo "--- T3: config_get dla nieznanego klucza = FATAL (exit 2) ---"
# config_fatal robi exit 2 w bieżącym procesie — wywołaj w subshellu.
if ( config_get "$SID" "nonexistent.key" >/dev/null 2>&1 ); then
    t_fail "config_get dla nieznanego klucza NIE zwrócił FATAL (FALSE PASS)"
else
    t_pass "config_get dla nieznanego klucza zwrócił FATAL (exit 2)"
fi

# ── T4: tighten (powyżej defaultu) przechodzi bez waivera ─────────────────
echo ""
echo "--- T4: tighten (powyżej defaultu) przechodzi bez waivera ---"
# Context rule dla task_type=test ustawia tighten coverage.min_percent=90.
SID_TIGHT="$(config_resolve '{"task_type":"test","files":["src/foo_test.go"],"tier":"0"}' "billing-api")"
VAL_TIGHT="$(config_get "$SID_TIGHT" "coverage.min_percent")"
if [ "$VAL_TIGHT" = "90" ]; then
    t_pass "tighten coverage.min_percent = $VAL_TIGHT (powyżej defaultu, bez waivera)"
else
    t_fail "tighten coverage.min_percent = '$VAL_TIGHT' (oczekiwano '90')"
fi

# ── T5: relax (poniżej floora) bez waivera = REJECTED ─────────────────────
echo ""
echo "--- T5: relax (poniżej floora) bez waivera = REJECTED ---"
# Context rule dla task_type=test ustawia relax coverage.min_percent=70.
# Floor=60, więc 70 >= 60 — to NIE jest poniżej floora. Aby przetestować
# REJECTED, użyjemy service config z wartością poniżej floora.
# Stwórz service config z coverage.min_percent=50 (poniżej floora=60).
TEST_SERVICE_DIR="$TEST_DIR/services"
mkdir -p "$TEST_SERVICE_DIR"
cat > "$TEST_SERVICE_DIR/risky-api.yaml" <<'YAML'
service: { id: risky-api, tier: 1 }
gates:
  coverage.min_percent: 50
YAML
export CONFIG_SERVICES_DIR="$TEST_SERVICE_DIR"

SID_RELAX="$(config_resolve '{"task_type":"default","files":["src/main.go"],"tier":"0"}' "risky-api")"
VAL_RELAX="$(config_get "$SID_RELAX" "coverage.min_percent")"
# Fail-closed: wartość poniżej floora bez waivera jest podnoszona do floora (60).
if [ "$VAL_RELAX" = "60" ]; then
    t_pass "relax poniżej floora bez waivera = REJECTED (wartość podniesiona do floora 60)"
else
    t_fail "relax poniżej floora = '$VAL_RELAX' (oczekiwano '60' — floor enforcement)"
fi

# ── T6: config_simulate wykrywa THRESHOLD_LOOSENED ─────────────────────────
echo ""
echo "--- T6: config_simulate wykrywa THRESHOLD_LOOSENED ---"
# Najpierw zapisz snapshot z wysoką wartością (stary config).
# Stwórz service config z coverage=95 (tighten), resolve, potem zmień na 70.
cat > "$TEST_SERVICE_DIR/risky-api.yaml" <<'YAML'
service: { id: risky-api, tier: 1 }
gates:
  coverage.min_percent: 95
YAML
SID_HIGH="$(config_resolve '{"task_type":"default","files":["src/main.go"],"tier":"0"}' "risky-api")"

# Teraz obniż do 70 (poniżej starego 95) — symulacja powinna wykryć THRESHOLD_LOOSENED.
cat > "$TEST_SERVICE_DIR/risky-api.yaml" <<'YAML'
service: { id: risky-api, tier: 1 }
gates:
  coverage.min_percent: 70
YAML
SIM_OUT="$(config_simulate '{"task_type":"default","files":["src/main.go"],"tier":"0"}' "risky-api" 2>&1)"
SIM_RC=$?
if [ "$SIM_RC" -ne 0 ] && printf '%s' "$SIM_OUT" | grep -q "THRESHOLD_LOOSENED"; then
    t_pass "config_simulate wykrył THRESHOLD_LOOSENED (rc=$SIM_RC)"
else
    t_fail "config_simulate NIE wykrył THRESHOLD_LOOSENED (rc=$SIM_RC, out=$SIM_OUT)"
fi

# ── T7: config_exemption_check blokuje klucz niekonfigurowalny ─────────────
echo ""
echo "--- T7: config_exemption_check blokuje klucz niekonfigurowalny ---"
if ( config_exemption_check "gates.self-001.enabled" >/dev/null 2>&1 ); then
    t_fail "config_exemption_check NIE zablokował niekonfigurowalnego klucza (FALSE PASS)"
else
    t_pass "config_exemption_check zablokował niekonfigurowalny klucz"
fi

# ── T8: brak registry.yaml → config_resolve = exit 2 (fail-closed) ─────────
echo ""
echo "--- T8: brak registry.yaml → config_resolve = exit 2 (fail-closed) ---"
export CONFIG_REGISTRY="$TEST_DIR/missing-registry.yaml"
if ( config_resolve '{"task_type":"default"}' "billing-api" >/dev/null 2>&1 ); then
    t_fail "config_resolve bez registry.yaml NIE zwrócił exit 2 (FALSE PASS)"
else
    t_pass "config_resolve bez registry.yaml zwrócił exit 2 (fail-closed)"
fi

# ── T9: tighten max_* poniżej floora PRZECHODZI ────────────────────────────
echo ""
echo "--- T9: tighten max_* poniżej floora PRZECHODZI ---"
# max_*: floor = górny limit. Tighten = obniżenie wartości. max_high tighten
# do 1 przy floor=3 → wynik 1 (nie 3). To łamie prawo #1 (tighten zawsze
# przechodzi) — zaostrzenie NIE może być odrzucone przez floor.
export CONFIG_REGISTRY="$TEST_REGISTRY"
TEST_SERVICE_DIR="$TEST_DIR/services"
mkdir -p "$TEST_SERVICE_DIR"
cat > "$TEST_SERVICE_DIR/tight-max-api.yaml" <<'YAML'
service: { id: tight-max-api, tier: 1 }
gates:
  security.sast.max_high: 1
YAML
export CONFIG_SERVICES_DIR="$TEST_SERVICE_DIR"
SID_TIGHT_MAX="$(config_resolve '{"task_type":"default","files":["src/main.go"],"tier":"0"}' "tight-max-api")"
VAL_TIGHT_MAX="$(config_get "$SID_TIGHT_MAX" "security.sast.max_high")"
if [ "$VAL_TIGHT_MAX" = "1" ]; then
    t_pass "tighten max_high do 1 (floor=3) = $VAL_TIGHT_MAX (tighten przechodzi, nie 3)"
else
    t_fail "tighten max_high do 1 = '$VAL_TIGHT_MAX' (oczekiwano '1' — tighten nie może być odrzucony przez floor)"
fi

# ── T10: relax max_* powyżej floora jest REJECTED ──────────────────────────
echo ""
echo "--- T10: relax max_* powyżej floora jest REJECTED ---"
# max_*: floor = górny limit. Relax = podniesienie wartości. max_high relax
# do 10 przy floor=3 → REJECTED, wynik 3 (nie możesz mieć limitu wyższego niż floor).
cat > "$TEST_SERVICE_DIR/relax-max-api.yaml" <<'YAML'
service: { id: relax-max-api, tier: 1 }
gates:
  security.sast.max_high: 10
YAML
SID_RELAX_MAX="$(config_resolve '{"task_type":"default","files":["src/main.go"],"tier":"0"}' "relax-max-api")"
VAL_RELAX_MAX="$(config_get "$SID_RELAX_MAX" "security.sast.max_high")"
if [ "$VAL_RELAX_MAX" = "3" ]; then
    t_pass "relax max_high do 10 (floor=3) = $VAL_RELAX_MAX (REJECTED, obniżone do floora 3)"
else
    t_fail "relax max_high do 10 = '$VAL_RELAX_MAX' (oczekiwano '3' — floor enforcement górny limit)"
fi

# ── T11: tighten min_* powyżej floora PRZECHODZI ───────────────────────────
echo ""
echo "--- T11: tighten min_* powyżej floora PRZECHODZI ---"
# min_*: floor = dolny limit. Tighten = podniesienie wartości. min_percent
# tighten do 95 przy floor=60 → wynik 95 (nie 60).
cat > "$TEST_SERVICE_DIR/tight-min-api.yaml" <<'YAML'
service: { id: tight-min-api, tier: 1 }
gates:
  coverage.min_percent: 95
YAML
SID_TIGHT_MIN="$(config_resolve '{"task_type":"default","files":["src/main.go"],"tier":"0"}' "tight-min-api")"
VAL_TIGHT_MIN="$(config_get "$SID_TIGHT_MIN" "coverage.min_percent")"
if [ "$VAL_TIGHT_MIN" = "95" ]; then
    t_pass "tighten min_percent do 95 (floor=60) = $VAL_TIGHT_MIN (tighten przechodzi)"
else
    t_fail "tighten min_percent do 95 = '$VAL_TIGHT_MIN' (oczekiwano '95')"
fi

# ── T12: relax min_* poniżej floora jest REJECTED ──────────────────────────
echo ""
echo "--- T12: relax min_* poniżej floora jest REJECTED ---"
# min_*: floor = dolny limit. Relax = obniżenie wartości. min_percent relax
# do 50 przy floor=60 → REJECTED, wynik 60 (nie możesz zejść poniżej floora).
cat > "$TEST_SERVICE_DIR/relax-min-api.yaml" <<'YAML'
service: { id: relax-min-api, tier: 1 }
gates:
  coverage.min_percent: 50
YAML
SID_RELAX_MIN="$(config_resolve '{"task_type":"default","files":["src/main.go"],"tier":"0"}' "relax-min-api")"
VAL_RELAX_MIN="$(config_get "$SID_RELAX_MIN" "coverage.min_percent")"
if [ "$VAL_RELAX_MIN" = "60" ]; then
    t_pass "relax min_percent do 50 (floor=60) = $VAL_RELAX_MIN (REJECTED, podniesione do floora 60)"
else
    t_fail "relax min_percent do 50 = '$VAL_RELAX_MIN' (oczekiwano '60' — floor enforcement dolny limit)"
fi

# ── T13: tier jako liczba bez cudzysłowu ("tier":1) → tighten tier1-critical ─
echo ""
echo "--- T13: tier jako liczba bez cudzysłowu (\"tier\":1) → tighten tier1-critical ---"
# Fail-open bug: parser wymagał "tier":"1" (string w cudzysłowie). Prawdziwy
# context JSON ma "tier":1 (liczba bez cudzysłowu) → CFG_TIER zostawał pusty →
# reguła tier1-critical (tier eq 1) nie była dopasowana → max_high=5 zamiast 1.
# Ten test weryfikuje, że liczba bez cudzysłowu jest poprawnie parsowana.
export CONFIG_REGISTRY="$TEST_REGISTRY"
TEST_SERVICE_DIR="$TEST_DIR/services"
mkdir -p "$TEST_SERVICE_DIR"
cat > "$TEST_SERVICE_DIR/tier1-num-api.yaml" <<'YAML'
service: { id: tier1-num-api, tier: 1 }
YAML
export CONFIG_SERVICES_DIR="$TEST_SERVICE_DIR"
SID_TIER1_NUM="$(config_resolve '{"task_type":"deploy","tier":1,"files":["src/api/billing.py"]}' "tier1-num-api")"
VAL_TIER1_NUM="$(config_get "$SID_TIER1_NUM" "security.sast.max_high")"
if [ "$VAL_TIER1_NUM" = "1" ]; then
    t_pass "tier:1 (liczba bez cudzysłowu) → max_high = $VAL_TIER1_NUM (tighten tier1-critical działa)"
else
    t_fail "tier:1 (liczba bez cudzysłowu) → max_high = '$VAL_TIER1_NUM' (oczekiwano '1' — fail-open!)"
fi

# ── T14: tier jako string w cudzysłowie ("tier":"1") → backward compat ─────
echo ""
echo "--- T14: tier jako string w cudzysłowie (\"tier\":\"1\") → backward compat ---"
SID_TIER1_STR="$(config_resolve '{"task_type":"deploy","tier":"1","files":["src/api/billing.py"]}' "tier1-num-api")"
VAL_TIER1_STR="$(config_get "$SID_TIER1_STR" "security.sast.max_high")"
if [ "$VAL_TIER1_STR" = "1" ]; then
    t_pass "tier:\"1\" (string w cudzysłowie) → max_high = $VAL_TIER1_STR (backward compat)"
else
    t_fail "tier:\"1\" (string w cudzysłowie) → max_high = '$VAL_TIER1_STR' (oczekiwano '1')"
fi

# ── T15: tier 3 (liczba) → reguła tier1-critical NIE dopasowana ────────────
echo ""
echo "--- T15: tier 3 (liczba) → reguła tier1-critical NIE dopasowana ---"
# Sedno: tier 3 NIE dostaje tighten do 1 (reguła tier1-critical wymaga tier eq 1).
# Serwis bez deklaracji max_high: default=5, ale floor=3 (górny limit dla max_*)
# wymusza 3. Kluczowe jest, że wynik to NIE 1 — brak zaostrzenia dla tier 3.
SID_TIER3_NUM="$(config_resolve '{"task_type":"deploy","tier":3,"files":["src/api/billing.py"]}' "tier1-num-api")"
VAL_TIER3_NUM="$(config_get "$SID_TIER3_NUM" "security.sast.max_high")"
if [ "$VAL_TIER3_NUM" != "1" ]; then
    t_pass "tier:3 (liczba) → max_high = $VAL_TIER3_NUM (reguła tier1-critical NIE dopasowana — brak tighten do 1)"
else
    t_fail "tier:3 (liczba) → max_high = '$VAL_TIER3_NUM' (oczekiwano != 1 — tier 3 nie powinien dostać zaostrzenia)"
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== CONFIG RESOLVER — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
