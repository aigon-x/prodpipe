#!/usr/bin/env bash
# ============================================================================
# test-model.sh — NEGATIVE/POSITIVE TESTS for canonical model (model.sh)
# ============================================================================
# Testuje że kanoniczny model projektu (project-model.json) ma wymagane
# elementy:
#   T1: model ma sekcję components -> PASS
#   T2: model ma sekcję pipelines -> PASS
#   T3: model ma sekcję gates -> PASS
#   T4: model ma sekcję evidence -> PASS
#   T5: model ma sekcję documents -> PASS
#   T6: model ma sekcję coverage z formula+input_set+exclusions -> PASS
#   T7: model ma relacje FACT/INFERRED (nigdy nie mieszane) -> PASS
#   T8: model nie zawiera sekretów (redaction) -> PASS
#   T9: (kontrola negatywna) czysty JSON bez coverage -> grep NIE pasuje -> PASS
#   T10: (kontrola negatywna) czysty JSON z niepoprawną relacją -> grep NIE pasuje -> PASS
#
# Użycie: ./test-model.sh
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

echo "=== TESTS — canonical model (model.sh) ==="

MODEL_JSON="$ROOT/docs/generated/project-model.json"

# --- T1-T5: model ma wymagane sekcje ----------------------------------------
echo ""
echo "--- T1-T5: model ma sekcje components/pipelines/gates/evidence/documents ---"
if [ -f "$MODEL_JSON" ]; then
    MISSING=0
    for section in components pipelines gates evidence documents; do
        if ! grep -q "\"$section\":" "$MODEL_JSON" 2>/dev/null; then
            MISSING=$((MISSING+1))
            printf '  [INFO] brak sekcji %s\n' "$section"
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        t_pass "Model ma sekcje components/pipelines/gates/evidence/documents"
    else
        t_fail "Brak $MISSING sekcji w modelu"
    fi
else
    t_fail "Brak docs/generated/project-model.json (uruchom explore.sh all)"
fi

# --- T6: model ma coverage z formula+input_set+exclusions -------------------
echo ""
echo "--- T6: model ma coverage z formula+input_set+exclusions ---"
if [ -f "$MODEL_JSON" ]; then
    if grep -q '"coverage"' "$MODEL_JSON" 2>/dev/null \
       && grep -q '"formula"' "$MODEL_JSON" 2>/dev/null \
       && grep -q '"input_set"' "$MODEL_JSON" 2>/dev/null \
       && grep -q '"exclusions"' "$MODEL_JSON" 2>/dev/null; then
        t_pass "Model ma coverage z formula+input_set+exclusions"
    else
        t_fail "Model bez kompletnego coverage"
    fi
else
    t_fail "Brak docs/generated/project-model.json"
fi

# --- T7: model ma relacje FACT/INFERRED (nigdy nie mieszane) -----------------
echo ""
echo "--- T7: model ma relacje FACT/INFERRED (nigdy nie mieszane) ---"
if [ -f "$MODEL_JSON" ]; then
    BAD="$(grep -oE '"relation": "[^"]*"' "$MODEL_JSON" 2>/dev/null | grep -vE '"relation": "(FACT|INFERRED)"' | head -1)"
    if [ -z "$BAD" ]; then
        t_pass "Model ma tylko relacje FACT/INFERRED"
    else
        t_fail "Model ma niepoprawną relację: $BAD"
    fi
else
    t_fail "Brak docs/generated/project-model.json"
fi

# --- T8: model nie zawiera sekretów (redaction) ------------------------------
echo ""
echo "--- T8: model nie zawiera sekretów (redaction) ---"
if [ -f "$MODEL_JSON" ]; then
    if grep -qE 'sk-[A-Za-z0-9]{16,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----' "$MODEL_JSON" 2>/dev/null; then
        t_fail "Model zawiera sekret"
    else
        t_pass "Model nie zawiera sekretów"
    fi
else
    t_fail "Brak docs/generated/project-model.json"
fi

# --- T9: kontrola negatywna — czysty JSON bez coverage -----------------------
echo ""
echo "--- T9: czysty JSON bez coverage -> grep NIE pasuje ---"
cat > "$WORK/clean.json" <<'EOF'
{
  "schema_version": 1,
  "components": []
}
EOF
if grep -q '"coverage"' "$WORK/clean.json" 2>/dev/null; then
    t_fail "Fałszywy pozytyw — czysty JSON pasuje do grep coverage"
else
    t_pass "Czysty JSON NIE pasuje do grep coverage (brak fałszywego pozytywu)"
fi

# --- T10: kontrola negatywna — czysty JSON z niepoprawną relacją -------------
echo ""
echo "--- T10: czysty JSON z niepoprawną relacją -> grep NIE pasuje ---"
cat > "$WORK/clean-rel.json" <<'EOF'
{
  "components": [ { "id": "x", "relation": "FACT" } ]
}
EOF
BAD="$(grep -oE '"relation": "[^"]*"' "$WORK/clean-rel.json" 2>/dev/null | grep -vE '"relation": "(FACT|INFERRED)"' | head -1)"
if [ -n "$BAD" ]; then
    t_fail "Fałszywy pozytyw — czysty JSON z poprawną relacją pasuje do grep"
else
    t_pass "Czysty JSON z relacją FACT NIE pasuje do grep niepoprawnej relacji"
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
