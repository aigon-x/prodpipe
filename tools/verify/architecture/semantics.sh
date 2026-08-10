#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# architecture/semantics.sh — AIGON Production Platform — Repository Certification Engine
# Moduł: ARCHITECTURE — SEMANTICS GATE
# Weryfikuje rejestr terminów (config/canonical/glossary.yaml) pod kątem
# spójności semantycznej i epistemic governance (FACT/INFERENCE/HYPOTHESIS/UNKNOWN).
#
# Checki:
#   SEM-001  Glossary istnieje
#   SEM-002  Glossary jest poprawnym YAML
#   SEM-003  Każdy termin ma canonical_definition
#   SEM-004  Każdy termin ma source + owner
#   SEM-005  Każdy termin ma epistemic_status (FACT|INFERENCE|HYPOTHESIS|UNKNOWN)
#   SEM-006  Slogan terms wykryte (INFORMATIONAL)
#   SEM-007  Epistemic governance — podsumowanie statusów (INFORMATIONAL)
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== ARCHITECTURE — SEMANTICS GATE ==="

GLOSSARY="config/canonical/glossary.yaml"

# ── SEM-001 Glossary istnieje ────────────────────────────────
if repo_file "$GLOSSARY"; then
  pass "SEM-001 Glossary istnieje" BLOCKING "$GLOSSARY"
else
  fail "SEM-001 Glossary istnieje" BLOCKING "Brak $GLOSSARY — rejestr terminów nie istnieje."
  # Bez glossary nie ma czego dalej sprawdzać — reszta checków jest
  # zależna od pliku. Zapisujemy evidence FAIL i kończymy.
  evidence_record "verify:semantics:FAIL" "verify" "architecture/semantics.sh"
  verify_module_exit
fi

# ── SEM-002 Glossary jest poprawnym YAML ─────────────────────
# Preferujemy pełną walidację python3+yaml; fallback strukturalny przez grep.
YAML_OK=0
if command -v python3 >/dev/null 2>&1 && python3 -c "import yaml" >/dev/null 2>&1; then
  if python3 - "$GLOSSARY" <<'PY' >/dev/null 2>&1
import sys, yaml
with open(sys.argv[1]) as f:
    data = yaml.safe_load(f)
if not isinstance(data, dict) or "terms" not in data:
    sys.exit(1)
PY
  then
    YAML_OK=1
  fi
else
  # Fallback strukturalny: kluczowe pola muszą występować.
  if grep -qE '^terms:' "$GLOSSARY" && grep -qE '^  [A-Za-z0-9_-]+:' "$GLOSSARY" \
     && grep -qE 'canonical_definition:' "$GLOSSARY" && grep -qE 'epistemic_status:' "$GLOSSARY"; then
    YAML_OK=1
  fi
fi

if [ "$YAML_OK" -eq 1 ]; then
  pass "SEM-002 Glossary jest poprawnym YAML" BLOCKING "Parsowalny (python3+yaml)."
else
  fail "SEM-002 Glossary jest poprawnym YAML" BLOCKING "Niepoprawny lub brak kluczowych pól (terms/canonical_definition/epistemic_status)."
fi

# ── Ekstrakcja terminów ──────────────────────────────────────
# Lista kluczy terminów z sekcji `terms:` (wiersze zaczynające się od 2 spacji,
# potem identyfikator, potem dwukropek — bez zagnieżdżonych pól).
TERMS="$(awk '/^terms:/{in_terms=1; next} /^[^ ]/{in_terms=0} in_terms && /^  [A-Za-z0-9_-]+:/{print $1}' "$GLOSSARY" | sed 's/:$//')"

# ── SEM-003 Każdy termin ma canonical_definition ─────────────
MISSING_DEF=""
for t in $TERMS; do
  # Wartość canonical_definition dla terminu t (wiersz "    canonical_definition:").
  if ! awk -v t="$t" '
    $0 ~ "^  " t ":" {cur=1; next}
    cur && /^  [A-Za-z0-9_-]+:/ {cur=0}
    cur && /^    canonical_definition:/ {found=1; exit}
    END {exit !found}
  ' "$GLOSSARY"; then
    MISSING_DEF="$MISSING_DEF $t"
  fi
done

if [ -z "$MISSING_DEF" ]; then
  pass "SEM-003 Każdy termin ma canonical_definition" BLOCKING "Wszystkie $(printf '%s' "$TERMS" | wc -w) terminy mają definicję."
else
  fail "SEM-003 Każdy termin ma canonical_definition" BLOCKING "Terminy bez canonical_definition:$MISSING_DEF"
fi

# ── SEM-004 Każdy termin ma source + owner ───────────────────
MISSING_SRC_OWN=""
for t in $TERMS; do
  if ! awk -v t="$t" '
    $0 ~ "^  " t ":" {cur=1; next}
    cur && /^  [A-Za-z0-9_-]+:/ {cur=0}
    cur && /^    source:/ {src=1}
    cur && /^    owner:/ {own=1}
    END {exit !(src && own)}
  ' "$GLOSSARY"; then
    MISSING_SRC_OWN="$MISSING_SRC_OWN $t"
  fi
done

if [ -z "$MISSING_SRC_OWN" ]; then
  pass "SEM-004 Każdy termin ma source + owner" BLOCKING "Wszystkie terminy mają source i owner."
else
  fail "SEM-004 Każdy termin ma source + owner" BLOCKING "Terminy bez source/owner:$MISSING_SRC_OWN"
fi

# ── SEM-005 Każdy termin ma epistemic_status ─────────────────
# Fail-closed (zgodnie z glossary.yaml):
#   1. Brak epistemic_status LUB wartość spoza {FACT, INFERENCE, HYPOTHESIS, UNKNOWN}
#      → FAIL (BLOCKING).
#   2. epistemic_status=UNKNOWN dla terminu krytycznego (wszystkie terminy w
#      `terms:` są krytyczne) → FAIL (BLOCKING) — to UNKNOWN_SEMANTICS dla
#      terminu krytycznego.
VALID_STATUS="FACT INFERENCE HYPOTHESIS UNKNOWN"
MISSING_STATUS=""
UNKNOWN_CRITICAL=""
for t in $TERMS; do
  STATUS="$(awk -v t="$t" '
    $0 ~ "^  " t ":" {cur=1; next}
    cur && /^  [A-Za-z0-9_-]+:/ {cur=0}
    cur && /^    epistemic_status:/ {sub(/^    epistemic_status:[[:space:]]*/, ""); print; exit}
  ' "$GLOSSARY")"
  if ! printf '%s\n' $VALID_STATUS | grep -qx "$STATUS"; then
    MISSING_STATUS="$MISSING_STATUS $t(${STATUS:-BRAK})"
  elif [ "$STATUS" = "UNKNOWN" ]; then
    # Termin krytyczny z UNKNOWN = UNKNOWN_SEMANTICS → FAIL (BLOCKING).
    UNKNOWN_CRITICAL="$UNKNOWN_CRITICAL $t"
  fi
done

SEM005_FAIL=""
[ -n "$MISSING_STATUS" ] && SEM005_FAIL="$SEM005_FAIL brak/niepoprawny:$MISSING_STATUS"
[ -n "$UNKNOWN_CRITICAL" ] && SEM005_FAIL="$SEM005_FAIL UNKNOWN-krytyczny:$UNKNOWN_CRITICAL"

if [ -z "$SEM005_FAIL" ]; then
  pass "SEM-005 Każdy termin ma epistemic_status" BLOCKING "Wszystkie terminy mają epistemic_status ∈ {FACT, INFERENCE, HYPOTHESIS, UNKNOWN} i żaden krytyczny nie jest UNKNOWN."
else
  fail "SEM-005 Każdy termin ma epistemic_status" BLOCKING "Fail-closed epistemic governance:$SEM005_FAIL"
fi

# ── SEM-006 Slogan terms wykryte (INFORMATIONAL) ─────────────
# Słowa-slogany w kontekście deklaratywnym bez definicji. To check
# INFORMATIONAL — raportuje liczbę trafień, nie blokuje.
SLOGANS="production ready|secure|trusted|safe|autonomous|critical|high risk|verified|canonical|resilient|sovereign"
# Skanujemy pliki śledzone przez git (repo_files), pomijając glossary i katalogi
# narzędzi/testów, żeby nie liczyć samej definicji sloganów.
HITS="$(repo_files | grep -vE '(^|/)(glossary\.yaml|tools/verify/|tests/|\.git/)' \
  | xargs grep -lInE "$SLOGANS" 2>/dev/null | wc -l)"
info "SEM-006 Slogan terms wykryte" "Liczba plików z potencjalnymi sloganami bez definicji: $HITS (INFORMATIONAL)."

# ── SEM-007 Epistemic governance (INFORMATIONAL) ─────────────
# Podsumowanie rozkładu epistemic_status — ile FACT/INFERENCE/HYPOTHESIS/UNKNOWN.
FACT_N=0; INF_N=0; HYP_N=0; UNK_N=0
for t in $TERMS; do
  STATUS="$(awk -v t="$t" '
    $0 ~ "^  " t ":" {cur=1; next}
    cur && /^  [A-Za-z0-9_-]+:/ {cur=0}
    cur && /^    epistemic_status:/ {sub(/^    epistemic_status:[[:space:]]*/, ""); print; exit}
  ' "$GLOSSARY")"
  case "$STATUS" in
    FACT) FACT_N=$((FACT_N+1)) ;;
    INFERENCE) INF_N=$((INF_N+1)) ;;
    HYPOTHESIS) HYP_N=$((HYP_N+1)) ;;
    UNKNOWN) UNK_N=$((UNK_N+1)) ;;
  esac
done
info "SEM-007 Epistemic governance" "Rozkład statusów: FACT=$FACT_N INFERENCE=$INF_N HYPOTHESIS=$HYP_N UNKNOWN=$UNK_N (INFORMATIONAL)."

# ── Evidence ─────────────────────────────────────────────────
if verify_blocked; then
  evidence_record "verify:semantics:FAIL" "verify" "architecture/semantics.sh"
else
  evidence_record "verify:semantics:PASS" "verify" "architecture/semantics.sh"
fi

verify_module_exit
