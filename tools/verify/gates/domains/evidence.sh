#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/evidence.sh — GATE-020 EVIDENCE
# Weryfikuje że każdy gate ma plik evidence z exit code i timestamp.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-020 EVIDENCE ==="

EVIDENCE_DIR="./artifacts/evidence/gates"

# ── EVIDENCE-001: katalog evidence istnieje ─────────────────
if [ -d "$EVIDENCE_DIR" ]; then
  pass "EVIDENCE-001 katalog evidence istnieje" BLOCKING "Katalog evidence obecny."
else
  fail "EVIDENCE-001 katalog evidence istnieje" BLOCKING "Brak katalogu evidence."
fi

# ── EVIDENCE-002: każdy gate ma plik evidence ───────────────
# Dla każdego gate_id w registry sprawdzamy plik GATE-XXX.evidence.
if [ -f "./tools/verify/gates/registry.sh" ]; then
  # shellcheck source=../registry.sh
  . ./tools/verify/gates/registry.sh
  MISSING_EVIDENCE=0
  MISSING_DETAIL=""
  for gate_id in $(registry_gate_ids); do
    if [ ! -f "$EVIDENCE_DIR/$gate_id.evidence" ]; then
      MISSING_EVIDENCE=$((MISSING_EVIDENCE+1))
      MISSING_DETAIL="$MISSING_DETAIL $gate_id"
    fi
  done
  if [ "$MISSING_EVIDENCE" -eq 0 ]; then
    pass "EVIDENCE-002 każdy gate ma evidence" BLOCKING "Wszystkie gate'y mają pliki evidence."
  else
    fail "EVIDENCE-002 każdy gate ma evidence" BLOCKING "$MISSING_EVIDENCE gate'ów bez evidence:$MISSING_DETAIL"
  fi
fi

# ── EVIDENCE-003: evidence ma exit code ─────────────────────
if [ -d "$EVIDENCE_DIR" ]; then
  NO_EXIT_CODE=0
  NO_EXIT_CODE_DETAIL=""
  while IFS= read -r f; do
    if ! grep -qE 'exit_code|EXIT_CODE' "$f" 2>/dev/null; then
      NO_EXIT_CODE=$((NO_EXIT_CODE+1))
      NO_EXIT_CODE_DETAIL="$NO_EXIT_CODE_DETAIL $(basename "$f")"
    fi
  done < <(find "$EVIDENCE_DIR" -name '*.evidence' 2>/dev/null)
  if [ "$NO_EXIT_CODE" -eq 0 ]; then
    pass "EVIDENCE-003 evidence ma exit code" BLOCKING "Wszystkie evidence mają exit code."
  else
    fail "EVIDENCE-003 evidence ma exit code" BLOCKING "$NO_EXIT_CODE evidence bez exit code:$NO_EXIT_CODE_DETAIL"
  fi
fi

# ── EVIDENCE-004: evidence ma timestamp ─────────────────────
if [ -d "$EVIDENCE_DIR" ]; then
  NO_TIMESTAMP=0
  NO_TIMESTAMP_DETAIL=""
  while IFS= read -r f; do
    if ! grep -qE 'timestamp|recorded_at|date' "$f" 2>/dev/null; then
      NO_TIMESTAMP=$((NO_TIMESTAMP+1))
      NO_TIMESTAMP_DETAIL="$NO_TIMESTAMP_DETAIL $(basename "$f")"
    fi
  done < <(find "$EVIDENCE_DIR" -name '*.evidence' 2>/dev/null)
  if [ "$NO_TIMESTAMP" -eq 0 ]; then
    pass "EVIDENCE-004 evidence ma timestamp" BLOCKING "Wszystkie evidence mają timestamp."
  else
    fail "EVIDENCE-004 evidence ma timestamp" BLOCKING "$NO_TIMESTAMP evidence bez timestamp:$NO_TIMESTAMP_DETAIL"
  fi
fi

verify_module_exit
