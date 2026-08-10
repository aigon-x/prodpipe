#!/usr/bin/env bash
# ============================================================================
# test-semantics.sh — ARCHITECTURAL SEMANTICS GATE (semantics.sh)
# ============================================================================
# Weryfikuje moduł tools/verify/architecture/semantics.sh:
#   T1: moduł działa bez błędu na glossary.yaml z wszystkimi terminami FACT
#       (bez UNKNOWN) → SEM-001..005 PASS, rc=0
#   T2: fail-closed — glossary.yaml bez canonical_definition → SEM-003 FAIL
#   T3: fail-closed — glossary.yaml bez epistemic_status → SEM-005 FAIL
#   T4: fail-closed — brak glossary.yaml → SEM-001 FAIL
#   T5: fail-closed — termin krytyczny z epistemic_status=UNKNOWN → SEM-005 FAIL
#       (UNKNOWN_SEMANTICS dla terminu krytycznego)
#   T6: fail-closed — termin UNKNOWN używany w kontekście WYKONAWCZYM
#       (executable security/policy/control) → SEM-008 FAIL (BLOCKING)
#   T7: termin UNKNOWN używany tylko w DOKUMENTACJI → SEM-008 WARN (nie FAIL)
#   T8: termin UNKNOWN używany w ARTEFAKCIE HISTORYCZNYM → SEM-008 INFO
#   T9: fail-closed — termin krytyczny UNKNOWN używany przez IMPLEMENTACJĘ
#       → SEM-011 FAIL (BLOCKING)
#   T10: dryf semantyczny (last_changed != introduced_at) → SEM-010 INFO
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# repo_files = git ls-files i verify_root = git rev-parse), więc nie dotykają
# prawdziwego repo ani równoległej pracy innych subagentów.
#
# Użycie: ./test-semantics.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
SEMANTICS_SH="$VERIFY_DIR/architecture/semantics.sh"
GLOSSARY_SRC="$VERIFY_DIR/../../config/canonical/glossary.yaml"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== ARCHITECTURAL SEMANTICS GATE TESTS ==="

# ── Helper: buduje izolowane repo git z glossary.yaml ──────────────────────
# Argumenty: <katalog_docelowy> <plik_glossary>
# Tworzy git repo, kopiuje glossary.yaml do config/canonical/, commituje.
make_isolated_repo() {
  local dir="$1" glossary="$2"
  mkdir -p "$dir/config/canonical"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "SEM Test" )
  cp "$glossary" "$dir/config/canonical/glossary.yaml"
  echo "# test" > "$dir/README.md"
  ( cd "$dir" && git add -A )
  ( cd "$dir" && git commit -qm "add glossary" )
}

# ── T1: moduł działa na glossary z wszystkimi terminami FACT ───────────────
echo ""
echo "--- T1: glossary z wszystkimi terminami FACT → SEM-001..005 PASS (rc=0) ---"
# Prawdziwy glossary ma trust-domain: UNKNOWN → SEM-005 FAIL. Dlatego T1
# buduje KOPIĘ z wszystkimi epistemic_status=FACT, żeby testować ścieżkę PASS.
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR" "$T5_DIR" "$T6_DIR" "$T7_DIR" "$T8_DIR" "$T9_DIR" "$T10_DIR"' EXIT
# Zbuduj glossary z wszystkimi terminami FACT (sed zamienia każdy epistemic_status na FACT).
T1_GLOSSARY="$T1_DIR/glossary-fact.yaml"
mkdir -p "$T1_DIR"
sed 's/^    epistemic_status: .*/    epistemic_status: FACT/' "$GLOSSARY_SRC" > "$T1_GLOSSARY"
make_isolated_repo "$T1_DIR/repo" "$T1_GLOSSARY"

# Ustawiamy VERIFY_STATE_DB na nieistniejącą bazę, żeby evidence_record
# nie psuł wyniku (rejestruje WARN, nie FAIL).
T1_OUT="$(cd "$T1_DIR/repo" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$SEMANTICS_SH" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "SEM-001 Glossary istnieje" \
   && printf '%s' "$T1_OUT" | grep -q "SEM-002 Glossary jest poprawnym YAML" \
   && printf '%s' "$T1_OUT" | grep -q "SEM-003 Każdy termin ma canonical_definition" \
   && printf '%s' "$T1_OUT" | grep -q "SEM-004 Każdy termin ma source + owner" \
   && printf '%s' "$T1_OUT" | grep -q "SEM-005 Każdy termin ma epistemic_status" \
   && ! printf '%s' "$T1_OUT" | grep -q "\[FAIL\]"; then
  t_pass "moduł wykonał SEM-001..005 bez FAIL (rc=$T1_RC)"
else
  t_fail "moduł NIE przeszedł ścieżki PASS (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -25
fi

# ── T2: fail-closed — brak canonical_definition → SEM-003 FAIL ─────────────
echo ""
echo "--- T2: glossary bez canonical_definition → SEM-003 FAIL (rc != 0) ---"
T2_DIR="$(mktemp -d)"
# Usuń canonical_definition z pierwszego terminu (sec-d).
T2_GLOSSARY="$T2_DIR/glossary-nodef.yaml"
mkdir -p "$T2_DIR"
awk '
  /^  sec-d:/ {in_sec=1}
  in_sec && /^    canonical_definition:/ {skip=1; next}
  in_sec && /^    [a-z_]+:/ && !/^    canonical_definition:/ {skip=0}
  !skip {print}
' "$GLOSSARY_SRC" > "$T2_GLOSSARY"
make_isolated_repo "$T2_DIR/repo" "$T2_GLOSSARY"

T2_OUT="$(cd "$T2_DIR/repo" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$SEMANTICS_SH" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "SEM-003 Każdy termin ma canonical_definition" \
   && printf '%s' "$T2_OUT" | grep -q "\[FAIL\]"; then
  t_pass "brak canonical_definition → SEM-003 FAIL (rc=$T2_RC)"
else
  t_fail "brak canonical_definition NIE dał SEM-003 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -25
fi

# ── T3: fail-closed — brak epistemic_status → SEM-005 FAIL ─────────────────
echo ""
echo "--- T3: glossary bez epistemic_status → SEM-005 FAIL (rc != 0) ---"
T3_DIR="$(mktemp -d)"
# Usuń epistemic_status z pierwszego terminu (sec-d).
T3_GLOSSARY="$T3_DIR/glossary-nostatus.yaml"
mkdir -p "$T3_DIR"
awk '
  /^  sec-d:/ {in_sec=1}
  in_sec && /^    epistemic_status:/ {skip=1; next}
  in_sec && /^    [a-z_]+:/ && !/^    epistemic_status:/ {skip=0}
  !skip {print}
' "$GLOSSARY_SRC" > "$T3_GLOSSARY"
make_isolated_repo "$T3_DIR/repo" "$T3_GLOSSARY"

T3_OUT="$(cd "$T3_DIR/repo" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$SEMANTICS_SH" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "SEM-005 Każdy termin ma epistemic_status" \
   && printf '%s' "$T3_OUT" | grep -q "\[FAIL\]"; then
  t_pass "brak epistemic_status → SEM-005 FAIL (rc=$T3_RC)"
else
  t_fail "brak epistemic_status NIE dał SEM-005 FAIL (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -25
fi

# ── T4: fail-closed — brak glossary.yaml → SEM-001 FAIL ────────────────────
echo ""
echo "--- T4: brak glossary.yaml → SEM-001 FAIL (rc != 0) ---"
T4_DIR="$(mktemp -d)"
mkdir -p "$T4_DIR/repo"
( cd "$T4_DIR/repo" && git init -q )
( cd "$T4_DIR/repo" && git config user.email "test@aigon.local" )
( cd "$T4_DIR/repo" && git config user.name "SEM Test" )
echo "# test" > "$T4_DIR/repo/README.md"
( cd "$T4_DIR/repo" && git add -A )
( cd "$T4_DIR/repo" && git commit -qm "no glossary" )

T4_OUT="$(cd "$T4_DIR/repo" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$SEMANTICS_SH" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "SEM-001 Glossary istnieje" \
   && printf '%s' "$T4_OUT" | grep -q "\[FAIL\]"; then
  t_pass "brak glossary.yaml → SEM-001 FAIL (rc=$T4_RC)"
else
  t_fail "brak glossary.yaml NIE dał SEM-001 FAIL (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -25
fi

# ── T5: fail-closed — termin krytyczny z UNKNOWN → SEM-005 FAIL ────────────
echo ""
echo "--- T5: termin krytyczny z epistemic_status=UNKNOWN → SEM-005 FAIL ---"
T5_DIR="$(mktemp -d)"
# Prawdziwy glossary ma trust-domain: UNKNOWN → SEM-005 MUSI dać FAIL.
make_isolated_repo "$T5_DIR/repo" "$GLOSSARY_SRC"

T5_OUT="$(cd "$T5_DIR/repo" && VERIFY_STATE_DB="$T5_DIR/nonexistent.db" bash "$SEMANTICS_SH" 2>&1)"
T5_RC=$?
if [ "$T5_RC" -ne 0 ] && printf '%s' "$T5_OUT" | grep -q "SEM-005 Każdy termin ma epistemic_status" \
   && printf '%s' "$T5_OUT" | grep -q "UNKNOWN-krytyczny" \
   && printf '%s' "$T5_OUT" | grep -q "\[FAIL\]"; then
  t_pass "termin krytyczny z UNKNOWN → SEM-005 FAIL (rc=$T5_RC)"
else
  t_fail "termin krytyczny z UNKNOWN NIE dał SEM-005 FAIL (rc=$T5_RC)"
  printf '%s\n' "$T5_OUT" | tail -25
fi

# ── T6: fail-closed — termin UNKNOWN w kontekście WYKONAWCZYM → SEM-008 FAIL ──
echo ""
echo "--- T6: termin UNKNOWN używany w kontekście WYKONAWCZYM → SEM-008 FAIL ---"
# Budujemy glossary z trust-domain: UNKNOWN + plik wykonywalny (policy.sh),
# który używa terminu trust-domain w kontekście security/policy/control.
T6_DIR="$(mktemp -d)"
mkdir -p "$T6_DIR/repo/config/canonical" "$T6_DIR/repo/tools/verify/security"
( cd "$T6_DIR/repo" && git init -q )
( cd "$T6_DIR/repo" && git config user.email "test@aigon.local" )
( cd "$T6_DIR/repo" && git config user.name "SEM Test" )
cp "$GLOSSARY_SRC" "$T6_DIR/repo/config/canonical/glossary.yaml"
# Plik wykonywalny używający trust-domain w kontekście security/policy.
cat > "$T6_DIR/repo/tools/verify/security/policy.sh" <<'EOF'
#!/usr/bin/env bash
# policy — kontrola dostępu oparta o trust-domain
set -euo pipefail
# trust-domain: granica zaufania dla autoryzacji
check_trust_domain() {
  local domain="$1"
  echo "checking trust-domain: $domain"
}
EOF
echo "# test" > "$T6_DIR/repo/README.md"
( cd "$T6_DIR/repo" && git add -A )
( cd "$T6_DIR/repo" && git commit -qm "add glossary + policy.sh" )

T6_OUT="$(cd "$T6_DIR/repo" && VERIFY_STATE_DB="$T6_DIR/nonexistent.db" bash "$SEMANTICS_SH" 2>&1)"
T6_RC=$?
if [ "$T6_RC" -ne 0 ] && printf '%s' "$T6_OUT" | grep -q "SEM-008 UNKNOWN w kontekście wykonawczym" \
   && printf '%s' "$T6_OUT" | grep -q "\[FAIL\]"; then
  t_pass "termin UNKNOWN w kontekście wykonawczym → SEM-008 FAIL (rc=$T6_RC)"
else
  t_fail "termin UNKNOWN w kontekście wykonawczym NIE dał SEM-008 FAIL (rc=$T6_RC)"
  printf '%s\n' "$T6_OUT" | tail -25
fi

# ── T7: termin UNKNOWN tylko w DOKUMENTACJI → SEM-008 WARN (nie FAIL) ──────
echo ""
echo "--- T7: termin UNKNOWN tylko w dokumentacji → SEM-008 WARN (nie FAIL) ---"
T7_DIR="$(mktemp -d)"
mkdir -p "$T7_DIR/repo/config/canonical" "$T7_DIR/repo/docs"
( cd "$T7_DIR/repo" && git init -q )
( cd "$T7_DIR/repo" && git config user.email "test@aigon.local" )
( cd "$T7_DIR/repo" && git config user.name "SEM Test" )
cp "$GLOSSARY_SRC" "$T7_DIR/repo/config/canonical/glossary.yaml"
# Dokumentacja używająca trust-domain (docs/).
cat > "$T7_DIR/repo/docs/architecture.md" <<'EOF'
# Architektura
trust-domain definiuje granicę zaufania w systemie.
EOF
echo "# test" > "$T7_DIR/repo/README.md"
( cd "$T7_DIR/repo" && git add -A )
( cd "$T7_DIR/repo" && git commit -qm "add glossary + docs" )

T7_OUT="$(cd "$T7_DIR/repo" && VERIFY_STATE_DB="$T7_DIR/nonexistent.db" bash "$SEMANTICS_SH" 2>&1)"
T7_RC=$?
if printf '%s' "$T7_OUT" | grep -q "SEM-008 UNKNOWN w dokumentacji" \
   && printf '%s' "$T7_OUT" | grep -q "\[WARN\]"; then
  t_pass "termin UNKNOWN w dokumentacji → SEM-008 WARN (rc=$T7_RC)"
else
  t_fail "termin UNKNOWN w dokumentacji NIE dał SEM-008 WARN (rc=$T7_RC)"
  printf '%s\n' "$T7_OUT" | tail -25
fi

# ── T8: termin UNKNOWN w ARTEFAKCIE HISTORYCZNYM → SEM-008 INFO ────────────
echo ""
echo "--- T8: termin UNKNOWN w artefakcie historycznym → SEM-008 INFO ---"
T8_DIR="$(mktemp -d)"
mkdir -p "$T8_DIR/repo/config/canonical" "$T8_DIR/repo/docs/decisions"
( cd "$T8_DIR/repo" && git init -q )
( cd "$T8_DIR/repo" && git config user.email "test@aigon.local" )
( cd "$T8_DIR/repo" && git config user.name "SEM Test" )
cp "$GLOSSARY_SRC" "$T8_DIR/repo/config/canonical/glossary.yaml"
# Artefakt historyczny (docs/decisions/) używający trust-domain.
cat > "$T8_DIR/repo/docs/decisions/ARCHITECTURAL-KNOWLEDGE-GAP-SEC-DARC.md" <<'EOF'
# Decyzja architektoniczna
trust-domain był rozważany jako granica zaufania (historyczny zapis).
EOF
echo "# test" > "$T8_DIR/repo/README.md"
( cd "$T8_DIR/repo" && git add -A )
( cd "$T8_DIR/repo" && git commit -qm "add glossary + decision" )

T8_OUT="$(cd "$T8_DIR/repo" && VERIFY_STATE_DB="$T8_DIR/nonexistent.db" bash "$SEMANTICS_SH" 2>&1)"
T8_RC=$?
if printf '%s' "$T8_OUT" | grep -q "SEM-008 UNKNOWN w artefaktach historycznych" \
   && printf '%s' "$T8_OUT" | grep -q "\[INFO\]"; then
  t_pass "termin UNKNOWN w artefakcie historycznym → SEM-008 INFO (rc=$T8_RC)"
else
  t_fail "termin UNKNOWN w artefakcie historycznym NIE dał SEM-008 INFO (rc=$T8_RC)"
  printf '%s\n' "$T8_OUT" | tail -25
fi

# ── T9: fail-closed — termin krytyczny UNKNOWN używany przez IMPLEMENTACJĘ → SEM-011 FAIL ──
echo ""
echo "--- T9: termin krytyczny UNKNOWN używany przez implementację → SEM-011 FAIL ---"
T9_DIR="$(mktemp -d)"
mkdir -p "$T9_DIR/repo/config/canonical" "$T9_DIR/repo/tools/verify/security"
( cd "$T9_DIR/repo" && git init -q )
( cd "$T9_DIR/repo" && git config user.email "test@aigon.local" )
( cd "$T9_DIR/repo" && git config user.name "SEM Test" )
cp "$GLOSSARY_SRC" "$T9_DIR/repo/config/canonical/glossary.yaml"
# Implementacja (executable) używająca trust-domain w kontroli dostępu.
cat > "$T9_DIR/repo/tools/verify/security/access.sh" <<'EOF'
#!/usr/bin/env bash
# access — kontrola dostępu oparta o trust-domain
set -euo pipefail
# trust-domain: granica zaufania dla autoryzacji (P0)
authorize() {
  local domain="$1"
  echo "authorizing in trust-domain: $domain"
}
EOF
echo "# test" > "$T9_DIR/repo/README.md"
( cd "$T9_DIR/repo" && git add -A )
( cd "$T9_DIR/repo" && git commit -qm "add glossary + access.sh" )

T9_OUT="$(cd "$T9_DIR/repo" && VERIFY_STATE_DB="$T9_DIR/nonexistent.db" bash "$SEMANTICS_SH" 2>&1)"
T9_RC=$?
if [ "$T9_RC" -ne 0 ] && printf '%s' "$T9_OUT" | grep -q "SEM-011 CRITICAL UNKNOWN USED BY IMPLEMENTATION" \
   && printf '%s' "$T9_OUT" | grep -q "\[FAIL\]"; then
  t_pass "termin krytyczny UNKNOWN używany przez implementację → SEM-011 FAIL (rc=$T9_RC)"
else
  t_fail "termin krytyczny UNKNOWN używany przez implementację NIE dał SEM-011 FAIL (rc=$T9_RC)"
  printf '%s\n' "$T9_OUT" | tail -25
fi

# ── T10: dryf semantyczny (last_changed != introduced_at) → SEM-010 INFO ───
echo ""
echo "--- T10: dryf semantyczny (last_changed != introduced_at) → SEM-010 INFO ---"
T10_DIR="$(mktemp -d)"
mkdir -p "$T10_DIR/repo/config/canonical"
( cd "$T10_DIR/repo" && git init -q )
( cd "$T10_DIR/repo" && git config user.email "test@aigon.local" )
( cd "$T10_DIR/repo" && git config user.name "SEM Test" )
# Glossary z dryfem: last_changed != introduced_at dla sec-d.
T10_GLOSSARY="$T10_DIR/glossary-drift.yaml"
mkdir -p "$T10_DIR"
sed 's/^    last_changed: "2026-08-10"/    last_changed: "2026-08-11"/' "$GLOSSARY_SRC" > "$T10_GLOSSARY"
cp "$T10_GLOSSARY" "$T10_DIR/repo/config/canonical/glossary.yaml"
echo "# test" > "$T10_DIR/repo/README.md"
( cd "$T10_DIR/repo" && git add -A )
( cd "$T10_DIR/repo" && git commit -qm "add glossary with drift" )

T10_OUT="$(cd "$T10_DIR/repo" && VERIFY_STATE_DB="$T10_DIR/nonexistent.db" bash "$SEMANTICS_SH" 2>&1)"
T10_RC=$?
if printf '%s' "$T10_OUT" | grep -q "SEM-010 Historyczny dryf semantyczny" \
   && printf '%s' "$T10_OUT" | grep -q "definicja/status zmienione"; then
  t_pass "dryf semantyczny → SEM-010 INFO (rc=$T10_RC)"
else
  t_fail "dryf semantyczny NIE dał SEM-010 INFO (rc=$T10_RC)"
  printf '%s\n' "$T10_OUT" | tail -25
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== ARCHITECTURAL SEMANTICS GATE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
