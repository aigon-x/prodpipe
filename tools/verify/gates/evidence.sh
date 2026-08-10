#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/evidence.sh — EVIDENCE STORE (PHASE 8)
# Uruchamia każdy gate z registry, łapie jego exit code i zapisuje
# maszynowo weryfikowalne evidence do artifacts/evidence/gates/.
#
# Format pliku evidence (GATE-XXX.evidence):
#   gate_id=<GATE-XXX>
#   domain=<domain>
#   name=<name>
#   command=<command>
#   exit_code=<0|1|2|3>
#   status=<PASS|FAIL|ERROR|NOT_APPLICABLE>
#   timestamp=<ISO-8601>
#   head=<short sha>
#   output=<skrót wyjścia>
#
# Exit code konwencja: 0=PASS, 1=FAIL, 2=ERROR, 3=NOT_APPLICABLE
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

GATES_DIR="./tools/verify/gates"
EVIDENCE_DIR="./artifacts/evidence/gates"
REGISTRY="$GATES_DIR/registry.sh"

# ── Wczytaj registry ────────────────────────────────────────
if [ ! -f "$REGISTRY" ]; then
  fail "EVIDENCE-STORE registry" BLOCKING "Brak registry.sh — nie można wygenerować evidence."
  verify_module_exit
fi
# shellcheck source=registry.sh
. "$REGISTRY"

# ── Utwórz katalog evidence ─────────────────────────────────
mkdir -p "$EVIDENCE_DIR"

# ── Wyczyść stare evidence (regeneracja) ────────────────────
# Usuwamy tylko pliki evidence z poprzedniego przebiegu, aby
# uniknąć STALE evidence (missing evidence / false green).
rm -f "$EVIDENCE_DIR"/*.evidence

HEAD_SHORT="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

say "=== EVIDENCE STORE (PHASE 8) ==="
say "Generowanie evidence dla $(registry_count) gate'ów..."

GENERATED=0
FAILED=0
# GATE-001 (gate-integrity) jest uruchamiany NA KOŃCU, po wygenerowaniu
# evidence dla wszystkich innych gate'ów — meta-gate sprawdza czy każdy
# gate ma evidence, więc musi widzieć kompletny zestaw.
for gate_id in $(registry_gate_ids | grep -v '^GATE-001$'); do
  cmd="$(registry_field "$gate_id" 8)"
  domain="$(registry_field "$gate_id" 2)"
  name="$(registry_field "$gate_id" 3)"

  if [ -z "$cmd" ] || [ ! -f "$cmd" ]; then
    # Brak implementacji — evidence ERROR (exit 2).
    printf 'gate_id=%s\ndomain=%s\nname=%s\ncommand=%s\nexit_code=2\nstatus=ERROR\ntimestamp=%s\nhead=%s\noutput=missing implementation\n' \
      "$gate_id" "$domain" "$name" "${cmd:-NONE}" "$NOW" "$HEAD_SHORT" \
      > "$EVIDENCE_DIR/$gate_id.evidence"
    FAILED=$((FAILED+1))
    warn "evidence $gate_id" "Brak implementacji: $cmd"
    continue
  fi

  # Uruchom gate i złap exit code + wyjście.
  output="$(bash "$cmd" 2>&1)"
  rc=$?

  # Mapuj exit code na status.
  case "$rc" in
    0) status="PASS" ;;
    1) status="FAIL" ;;
    2) status="ERROR" ;;
    3) status="NOT_APPLICABLE" ;;
    *) status="ERROR" ;;
  esac

  # Skrót wyjścia (pierwsze 500 znaków, bez kontrolnych).
  output_short="$(printf '%s' "$output" | tr '\n' ' ' | cut -c1-500)"

  # Zapisz evidence.
  printf 'gate_id=%s\ndomain=%s\nname=%s\ncommand=%s\nexit_code=%s\nstatus=%s\ntimestamp=%s\nhead=%s\noutput=%s\n' \
    "$gate_id" "$domain" "$name" "$cmd" "$rc" "$status" "$NOW" "$HEAD_SHORT" "$output_short" \
    > "$EVIDENCE_DIR/$gate_id.evidence"

  GENERATED=$((GENERATED+1))
  if [ "$rc" -ne 0 ]; then
    FAILED=$((FAILED+1))
  fi
  say "  $gate_id -> $status (exit $rc)"
done

# ── GATE-001 (meta-gate) na końcu ───────────────────────────
gate_id="GATE-001"
cmd="$(registry_field "$gate_id" 8)"
domain="$(registry_field "$gate_id" 2)"
name="$(registry_field "$gate_id" 3)"
if [ -n "$cmd" ] && [ -f "$cmd" ]; then
  output="$(bash "$cmd" 2>&1)"
  rc=$?
  case "$rc" in
    0) status="PASS" ;;
    1) status="FAIL" ;;
    2) status="ERROR" ;;
    3) status="NOT_APPLICABLE" ;;
    *) status="ERROR" ;;
  esac
  output_short="$(printf '%s' "$output" | tr '\n' ' ' | cut -c1-500)"
  printf 'gate_id=%s\ndomain=%s\nname=%s\ncommand=%s\nexit_code=%s\nstatus=%s\ntimestamp=%s\nhead=%s\noutput=%s\n' \
    "$gate_id" "$domain" "$name" "$cmd" "$rc" "$status" "$NOW" "$HEAD_SHORT" "$output_short" \
    > "$EVIDENCE_DIR/$gate_id.evidence"
  GENERATED=$((GENERATED+1))
  if [ "$rc" -ne 0 ]; then
    FAILED=$((FAILED+1))
  fi
  say "  $gate_id -> $status (exit $rc)"
fi

say ""
say "Wygenerowano $GENERATED evidence, $FAILED z niezerowym exit code."

# ── Podsumowanie ────────────────────────────────────────────
if [ "$GENERATED" -eq "$(registry_count)" ]; then
  pass "EVIDENCE-STORE wszystkie gate'y mają evidence" BLOCKING "$GENERATED/$GENERATED evidence wygenerowane."
else
  fail "EVIDENCE-STORE wszystkie gate'y mają evidence" BLOCKING "Wygenerowano $GENERATED z $(registry_count)."
fi

verify_module_exit
