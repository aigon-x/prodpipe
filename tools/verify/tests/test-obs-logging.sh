#!/usr/bin/env bash
# ============================================================================
# test-obs-logging.sh — OBS-BASELINE — LOGGING GATE tests (OBS-01, OBS-02)
# ============================================================================
# Weryfikuje, że:
#   T1: obs-logging-check.sh przechodzi na świeżym projekcie (PASS, rc=0)
#   T2: OBS-02 scrubbing działa — kanarek (email+token) NIE przechodzi
#       w czystej postaci przez lib/log.sh
#   T3: OBS-01 wykrywa ad-hoc logging — dodanie echo w kodzie domenowym → FAIL
#   T4: OBS-01b walidacja struktury JSON (level + ts + msg)
#
# Użycie: ./test-obs-logging.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
OBS_CHECK="$VERIFY_DIR/obs-logging-check.sh"
LOG_SH="$(cd "$VERIFY_DIR/../.." && pwd)/lib/log.sh"

# --- Kolory (z lib.sh) -----------------------------------------------------
# shellcheck source=core/lib.sh
. "$VERIFY_DIR/core/lib.sh"

# --- Liczniki --------------------------------------------------------------
PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  %s%s%s\n' "$C_GREEN" "[PASS] $*" "$C_RESET"; }
t_fail() { FAIL=$((FAIL+1)); printf '  %s%s%s\n' "$C_RED" "[FAIL] $*" "$C_RESET"; }

# --- Helper: buduje izolowane repo git z lib/log.sh + tools/ ---------------
# Argumenty: <katalog_docelowy>
# Tworzy git repo, kopiuje lib/log.sh i minimalny kod domenowy (tools/scripts/),
# commituje. Symuluje świeży projekt z szablonu.
make_isolated_repo() {
  local dir="$1"
  mkdir -p "$dir/lib" "$dir/tools/scripts"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "OBS Test" )
  cp "$LOG_SH" "$dir/lib/log.sh"
  # Minimalny kod domenowy — czysty (bez ad-hoc logowania).
  cat > "$dir/tools/scripts/example.sh" <<'EOF'
#!/usr/bin/env bash
# Przykładowy skrypt domenowy — używa lib/log.sh (jedyny dozwolony kanał).
set -u
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/log.sh"
log_info "start"
EOF
  echo "# test" > "$dir/README.md"
  ( cd "$dir" && git add -A )
  ( cd "$dir" && git commit -qm "add obs skeleton" )
}

echo "=== OBS-BASELINE — LOGGING GATE TESTS ==="

# ── T1: moduł przechodzi na świeżym projekcie ──────────────────────────────
echo ""
echo "--- T1: obs-logging-check.sh PASS na świeżym projekcie (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T3_DIR"' EXIT
make_isolated_repo "$T1_DIR/repo"
T1_OUT="$(cd "$T1_DIR/repo" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "OBS-01 No ad-hoc logging" \
   && printf '%s' "$T1_OUT" | grep -q "OBS-02 PII scrubbing" \
   && printf '%s' "$T1_OUT" | grep -q "OBS-01b Structured JSON logging" \
   && ! printf '%s' "$T1_OUT" | grep -q "\[FAIL\]"; then
  t_pass "moduł wykonał OBS-01/02/01b bez FAIL (rc=$T1_RC)"
else
  t_fail "moduł NIE przeszedł ścieżki PASS (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -25
fi

# ── T2: OBS-02 scrubbing działa (kanarek zamaskowany) ──────────────────────
echo ""
echo "--- T2: OBS-02 scrubbing — kanarek (email+token) NIE przechodzi ---"
CANARY_EMAIL="canary-obs02@example.com"
CANARY_TOKEN="sk-canary-obs02-1234567890abcdef"
CANARY_OUT="$(LOG_SERVICE=canary bash -c '. "$0"; log_error "user=$CANARY_EMAIL token=$CANARY_TOKEN"' "$LOG_SH" 2>&1)"
if ! printf '%s' "$CANARY_OUT" | grep -qF "$CANARY_EMAIL" \
   && ! printf '%s' "$CANARY_OUT" | grep -qF "$CANARY_TOKEN"; then
  t_pass "kanarek email+token zamaskowany przez scrubbing"
else
  t_fail "kanarek przeszedł przez scrubbing — OBS-02 to placebo"
  printf '%s\n' "$CANARY_OUT"
fi

# ── T3: OBS-01 wykrywa ad-hoc logging (negatywny) ──────────────────────────
echo ""
echo "--- T3: OBS-01 wykrywa echo w kodzie domenowym → FAIL (rc != 0) ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR/repo"
# Dodaj ad-hoc echo do kodu domenowego (poza lib/log.sh).
cat > "$T3_DIR/repo/tools/scripts/bad.sh" <<'EOF'
#!/usr/bin/env bash
echo "ad-hoc log bez lib/log.sh"
EOF
( cd "$T3_DIR/repo" && git add -A && git commit -qm "add bad logging" )
T3_OUT="$(cd "$T3_DIR/repo" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] OBS-01"; then
  t_pass "OBS-01 wykrył ad-hoc echo (rc=$T3_RC)"
else
  t_fail "OBS-01 NIE wykrył ad-hoc echo (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -15
fi

# ── T4: OBS-01b walidacja struktury JSON ───────────────────────────────────
echo ""
echo "--- T4: OBS-01b — emisja ma level + ts + msg (JSON line) ---"
SAMPLE_OUT="$(LOG_SERVICE=canary bash -c '. "$0"; log_info "hello world"' "$LOG_SH" 2>&1)"
if printf '%s' "$SAMPLE_OUT" | grep -qE '"level":"info"' \
   && printf '%s' "$SAMPLE_OUT" | grep -qE '"ts":"[0-9]{4}-[0-9]{2}-[0-9]{2}T' \
   && printf '%s' "$SAMPLE_OUT" | grep -qE '"msg":"hello world"'; then
  t_pass "emisja ma level + ts + msg (JSON line)"
else
  t_fail "emisja NIE ma kompletnej struktury JSON"
  printf '%s\n' "$SAMPLE_OUT"
fi

# ── Podsumowanie -----------------------------------------------------------
echo ""
echo "=== OBS-BASELINE — LOGGING GATE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
