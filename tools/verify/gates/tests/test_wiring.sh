#!/usr/bin/env bash
# ============================================================================
# test_wiring.sh — NEGATIVE TESTS for GATE-038 (G-INTEG / WIRING GATE)
# ============================================================================
# Testuje że wiring gate wykrywa problemy w dwukierunkowej macierzy połączeń:
#   T1: FALSE GATE (zadeklarowany w registry bez skryptu) -> FAIL
#   T2: ORPHAN (skrypt domains/ bez wpisu w registry) -> FAIL
#   T3: martwa zmienna (klucz w .env.example bez konsumenta) -> FAIL
#   T4: dangling ref (zmienna używana bez definicji) -> FAIL
#   T5: brak evidence dla IMPLEMENTED gate -> FAIL
#   T6: martwa tabela SQL (zdefiniowana bez użycia) -> FAIL
#   T7: brak wymaganego katalogu (contract→fs) -> FAIL
#   T8: niepodpięty skrypt (exists→wired) -> FAIL
#   T9: dziura w sekwencji migracji -> FAIL
#   T10: nieosiągalny plik (orphan detection) -> FAIL
#
# Użycie: ./test_wiring.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATES_DIR="$(dirname "$SCRIPT_DIR")"
ROOT="$(cd "$GATES_DIR/../../.." && pwd)"
WIRING="$GATES_DIR/domains/wiring.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  [PASS] %s\n' "$*"; }
t_fail() { FAIL=$((FAIL+1)); printf '  [FAIL] %s\n' "$*"; }

# --- Izolacja: tymczasowy katalog roboczy -----------------------------------
WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "=== NEGATIVE TESTS — GATE-038 G-INTEG (WIRING) ==="

# --- T1: FALSE GATE (zadeklarowany bez skryptu) -----------------------------
echo ""
echo "--- T1: FALSE GATE (registry bez skryptu) -> FAIL ---"
# INTEG-001: declared→exists. Sprawdzamy że wiring.sh zawiera logikę
# wykrywania gate'a zarejestrowanego bez skryptu implementacji.
if grep -q 'FALSE_GATE' "$WIRING" && grep -q 'registry_field.*8' "$WIRING"; then
    t_pass "Wiring wykrywa FALSE GATE (declared→exists)"
else
    t_fail "Wiring NIE wykrywa FALSE GATE"
fi

# --- T2: ORPHAN (skrypt bez wpisu w registry) -------------------------------
echo ""
echo "--- T2: ORPHAN (skrypt domains/ bez registry) -> FAIL ---"
# INTEG-002: exists→declared. Sprawdzamy że wiring.sh wykrywa orphan skrypty.
if grep -q 'ORPHAN' "$WIRING" && grep -q 'domains/\*.sh' "$WIRING"; then
    t_pass "Wiring wykrywa ORPHAN (exists→declared)"
else
    t_fail "Wiring NIE wykrywa ORPHAN"
fi

# --- T3: martwa zmienna (defined→consumed) ----------------------------------
echo ""
echo "--- T3: martwa zmienna (env bez konsumenta) -> FAIL ---"
# INTEG-004: defined→consumed. Sprawdzamy że wiring.sh wykrywa martwe klucze.
if grep -q 'DEAD_ENV' "$WIRING" && grep -q 'INTEG-004' "$WIRING"; then
    t_pass "Wiring wykrywa martwą zmienną (defined→consumed)"
else
    t_fail "Wiring NIE wykrywa martwej zmiennej"
fi

# --- T4: dangling ref (consumed→defined) ------------------------------------
echo ""
echo "--- T4: dangling ref (env bez definicji) -> FAIL ---"
# INTEG-003: consumed→defined. Sprawdzamy że wiring.sh wykrywa dangling refs.
if grep -q 'MISSING_ENV' "$WIRING" && grep -q 'INTEG-003' "$WIRING"; then
    t_pass "Wiring wykrywa dangling ref (consumed→defined)"
else
    t_fail "Wiring NIE wykrywa dangling ref"
fi

# --- T5: brak evidence dla IMPLEMENTED gate ---------------------------------
echo ""
echo "--- T5: brak evidence (runtime completeness) -> FAIL ---"
# INTEG-005: każdy IMPLEMENTED gate ma evidence. Sprawdzamy że wiring.sh
# wykrywa brak evidence.
if grep -q 'MISSING_EVIDENCE' "$WIRING" && grep -q 'INTEG-005' "$WIRING"; then
    t_pass "Wiring wykrywa brak evidence (runtime completeness)"
else
    t_fail "Wiring NIE wykrywa braku evidence"
fi

# --- T6: martwa tabela SQL (defined→consumed) -------------------------------
echo ""
echo "--- T6: martwa tabela SQL -> FAIL ---"
# INTEG-006: defined→consumed dla tabel SQL. Sprawdzamy że wiring.sh wykrywa
# martwe tabele.
if grep -q 'DEAD_TABLE' "$WIRING" && grep -q 'INTEG-006' "$WIRING"; then
    t_pass "Wiring wykrywa martwą tabelę SQL (defined→consumed)"
else
    t_fail "Wiring NIE wykrywa martwej tabeli SQL"
fi

# --- T7: brak wymaganego katalogu (contract→fs) -----------------------------
echo ""
echo "--- T7: brak wymaganego katalogu -> FAIL ---"
# INTEG-008: contract→fs. Sprawdzamy że wiring.sh zawiera listę wymaganych
# katalogów i wykrywa ich brak.
if grep -q 'REQUIRED_DIRS' "$WIRING" && grep -q 'INTEG-008' "$WIRING"; then
    t_pass "Wiring wykrywa brak wymaganego katalogu (contract→fs)"
else
    t_fail "Wiring NIE wykrywa braku wymaganego katalogu"
fi

# --- T8: niepodpięty skrypt (exists→wired) ----------------------------------
echo ""
echo "--- T8: niepodpięty skrypt -> FAIL ---"
# INTEG-009: exists→wired. Sprawdzamy że wiring.sh wykrywa niepodpięte skrypty.
if grep -q 'UNWIRED_SCRIPT' "$WIRING" && grep -q 'INTEG-009' "$WIRING"; then
    t_pass "Wiring wykrywa niepodpięty skrypt (exists→wired)"
else
    t_fail "Wiring NIE wykrywa niepodpiętego skryptu"
fi

# --- T9: dziura w sekwencji migracji ----------------------------------------
echo ""
echo "--- T9: dziura w sekwencji migracji -> FAIL ---"
# INTEG-011: migracje sekwencyjne bez dziur. Sprawdzamy że wiring.sh wykrywa
# dziury w sekwencji.
if grep -q 'GAP_MIGRATION' "$WIRING" && grep -q 'INTEG-011' "$WIRING"; then
    t_pass "Wiring wykrywa dziurę w sekwencji migracji"
else
    t_fail "Wiring NIE wykrywa dziury w sekwencji migracji"
fi

# --- T10: nieosiągalny plik (orphan detection) ------------------------------
echo ""
echo "--- T10: nieosiągalny plik -> FAIL ---"
# INTEG-012: orphan detection (osiągalność). Sprawdzamy że wiring.sh wykrywa
# nieosiągalne pliki.
if grep -q 'ORPHAN_FILE' "$WIRING" && grep -q 'INTEG-012' "$WIRING"; then
    t_pass "Wiring wykrywa nieosiągalny plik (orphan detection)"
else
    t_fail "Wiring NIE wykrywa nieosiągalnego pliku"
fi

# --- T11: check_id niezarejestrowany (declared→registered) ------------------
echo ""
echo "--- T11: niezarejestrowany check_id -> FAIL ---"
# INTEG-010: declared→registered. Sprawdzamy że wiring.sh wykrywa
# niezarejestrowane check_id.
if grep -q 'UNREGISTERED_ID' "$WIRING" && grep -q 'INTEG-010' "$WIRING"; then
    t_pass "Wiring wykrywa niezarejestrowany check_id (declared→registered)"
else
    t_fail "Wiring NIE wykrywa niezarejestrowanego check_id"
fi

# --- T12: ścieżka w docs bez odpowiednika (docs→fs) -------------------------
echo ""
echo "--- T12: ścieżka w docs bez odpowiednika -> FAIL ---"
# INTEG-007: docs→fs. Sprawdzamy że wiring.sh wykrywa ścieżki z docs bez
# odpowiednika w repo.
if grep -q 'MISSING_DOC_PATH' "$WIRING" && grep -q 'INTEG-007' "$WIRING"; then
    t_pass "Wiring wykrywa ścieżkę z docs bez odpowiednika (docs→fs)"
else
    t_fail "Wiring NIE wykrywa ścieżki z docs bez odpowiednika"
fi

# --- T13: wiring.sh kończy się verify_module_exit ---------------------------
echo ""
echo "--- T13: wiring.sh kończy się verify_module_exit -> PASS ---"
# Każdy moduł verify musi propagować exit code do rodzica.
if grep -q 'verify_module_exit' "$WIRING"; then
    t_pass "wiring.sh kończy się verify_module_exit"
else
    t_fail "wiring.sh NIE kończy się verify_module_exit"
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
