#!/usr/bin/env bash
# ============================================================================
# test-graphs.sh — NEGATIVE/POSITIVE TESTS for Mermaid graphs (graphs.sh)
# ============================================================================
# Testuje że katalog grafów Mermaid (docs/graphs/) ma wymagane pliki:
#   T1: katalog docs/graphs/ istnieje -> PASS
#   T2: README.md istnieje -> PASS
#   T3: architecture.mmd istnieje -> PASS
#   T4: gates.mmd istnieje -> PASS
#   T5: pipelines.mmd istnieje -> PASS
#   T6: documentation.mmd istnieje -> PASS
#   T7: traceability.mmd istnieje -> PASS
#   T8: configuration.mmd istnieje -> PASS
#   T9: (kontrola negatywna) czysty katalog bez .mmd -> grep NIE pasuje -> PASS
#   T10: (kontrola negatywna) czysty plik bez 'graph' -> grep NIE pasuje -> PASS
#
# Użycie: ./test-graphs.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  [PASS] %s\n' "$*"; }
t_fail() { FAIL=$((FAIL+1)); printf '  [FAIL] %s\n' "$*"; }

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "=== TESTS — Mermaid graphs (graphs.sh) ==="

GRAPHS_DIR="$ROOT/docs/graphs"

# Lista wymaganych grafów.
GRAPHS=(
  "architecture.mmd"
  "gates.mmd"
  "pipelines.mmd"
  "documentation.mmd"
  "traceability.mmd"
  "configuration.mmd"
  "dependencies.mmd"
  "evidence.mmd"
  "temporal.mmd"
  "tasks.mmd"
  "findings.mmd"
  "source-of-truth.mmd"
  "full-system.mmd"
)

# --- T1: katalog docs/graphs/ istnieje ---------------------------------------
echo ""
echo "--- T1: katalog docs/graphs/ istnieje ---"
if [ -d "$GRAPHS_DIR" ]; then
    t_pass "docs/graphs/ istnieje"
else
    t_fail "Brak katalogu docs/graphs/ (uruchom explore.sh all)"
fi

# --- T2: README.md istnieje --------------------------------------------------
echo ""
echo "--- T2: README.md istnieje ---"
if [ -f "$GRAPHS_DIR/README.md" ]; then
    t_pass "docs/graphs/README.md istnieje"
else
    t_fail "Brak docs/graphs/README.md"
fi

# --- T3-T8: wymagane grafy istnieją ------------------------------------------
echo ""
echo "--- T3-T8: wymagane grafy istnieją ---"
if [ -d "$GRAPHS_DIR" ]; then
    MISSING=0
    for g in "${GRAPHS[@]}"; do
        if [ ! -f "$GRAPHS_DIR/$g" ]; then
            MISSING=$((MISSING+1))
            printf '  [INFO] brak grafu %s\n' "$g"
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        t_pass "Wszystkie 13 grafów Mermaid istnieją"
    else
        t_fail "Brak $MISSING grafów w docs/graphs/"
    fi
else
    t_fail "Brak katalogu docs/graphs/"
fi

# --- T9: kontrola negatywna — czysty katalog bez .mmd ------------------------
echo ""
echo "--- T9: czysty katalog bez .mmd -> grep NIE pasuje ---"
mkdir -p "$WORK/empty"
if ls "$WORK/empty"/*.mmd >/dev/null 2>&1; then
    t_fail "Fałszywy pozytyw — czysty katalog ma .mmd"
else
    t_pass "Czysty katalog NIE ma .mmd (brak fałszywego pozytywu)"
fi

# --- T10: kontrola negatywna — czysty plik bez 'graph' -----------------------
echo ""
echo "--- T10: czysty plik bez 'graph' -> grep NIE pasuje ---"
cat > "$WORK/clean.mmd" <<'EOF'
%% czysty plik bez deklaracji grafu
EOF
if grep -qE '^graph ' "$WORK/clean.mmd" 2>/dev/null; then
    t_fail "Fałszywy pozytyw — czysty plik pasuje do grep graph"
else
    t_pass "Czysty plik NIE pasuje do grep graph (brak fałszywego pozytywu)"
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
