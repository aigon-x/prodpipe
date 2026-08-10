#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-039 — PIPELINE GOVERNANCE (Pipeline Governance / Integrity)
# Rodzina: RUNTIME | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje integralność katalogu pipeline'ów (Pipeline Operating System):
#   * FAIL-CLOSED   — każdy pipeline zadeklarowany jako IMPLEMENTED ma skrypt
#   * STATUS-SPÓJNOŚĆ — statusy w pipelines.yaml są spójne (IMPLEMENTED/PROPOSED)
#   * CONTRACT-REJESTR — pipeline_contract i pipeline_evidence mają wpisy
#                        (luka: tabele puste mimo istnienia p_contract/p_evidence)
#
# Pipeline Contract: DISCOVER → CONTRACT → EXECUTE → TEST → EVIDENCE → VERIFY → REGISTER → REPORT
# Dual Verdict: IMPLEMENTATION (czy pipeline jest poprawnie zbudowany) vs REPOSITORY (czy repo spełnia kontrakt)
# ─────────────────────────────────────────────────────────────
set -u

# ── Wczytaj core ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
. "$AUTOMATION_DIR/core/lib.sh"
. "$AUTOMATION_DIR/core/pipelines.sh"

ROOT="$(p_root)"
cd "$ROOT"

# ── DISCOVER ────────────────────────────────────────────────
p_say "=== P-039 PIPELINE GOVERNANCE ==="
p_say "Weryfikacja integralności katalogu pipeline'ów (fail-closed, statusy, rejestry)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-039"

# ── EXECUTE ─────────────────────────────────────────────────
GAP_COUNT=0
BAD_STATUS_COUNT=0
CONTRACT_REG_EMPTY=0
EVIDENCE_REG_EMPTY=0

# 1. FAIL-CLOSED — każdy pipeline IMPLEMENTED musi mieć odpowiadający skrypt.
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  rest="${entry#*|}"
  rest="${rest#*|}"
  scr="${rest%%|*}"
  rest="${rest#*|}"
  rest="${rest#*|}"
  st="${rest%%|*}"
  if [ "$st" = "IMPLEMENTED" ]; then
    if [ ! -f "$AUTOMATION_DIR/$scr" ]; then
      GAP_COUNT=$((GAP_COUNT+1))
      p_fail "GOVERNANCE-FAIL-CLOSED: $eid" BLOCKING "Pipeline zadeklarowany jako IMPLEMENTED, a skrypt nie istnieje: $scr"
    fi
  fi
done

# 2. STATUS-SPÓJNOŚĆ — statusy muszą być IMPLEMENTED lub PROPOSED.
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  rest="${entry#*|}"
  rest="${rest#*|}"
  rest="${rest#*|}"
  rest="${rest#*|}"
  st="${rest%%|*}"
  if [ "$st" != "IMPLEMENTED" ] && [ "$st" != "PROPOSED" ]; then
    BAD_STATUS_COUNT=$((BAD_STATUS_COUNT+1))
    p_fail "GOVERNANCE-STATUS: $eid" BLOCKING "Nieznany status pipeline'a: '$st' (oczekiwano IMPLEMENTED|PROPOSED)"
  fi
done

# 3. CONTRACT-REJESTR — pipeline_contract i pipeline_evidence powinny mieć wpisy.
#    (audyt: tabele puste mimo istnienia p_contract/p_evidence w lib.sh).
DB="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$DB" ]; then
  PC_COUNT="$(sqlite3 "$DB" "SELECT COUNT(*) FROM pipeline_contract;" 2>/dev/null || echo 0)"
  PE_COUNT="$(sqlite3 "$DB" "SELECT COUNT(*) FROM pipeline_evidence;" 2>/dev/null || echo 0)"
  if [ "${PC_COUNT:-0}" -eq 0 ]; then
    CONTRACT_REG_EMPTY=1
    p_warn "GOVERNANCE-CONTRACT-REGISTRY" "Tabela pipeline_contract jest PUSTA (0 wierszy) — luka do naprawy, nie błąd pipeline'a"
  fi
  if [ "${PE_COUNT:-0}" -eq 0 ]; then
    EVIDENCE_REG_EMPTY=1
    p_warn "GOVERNANCE-EVIDENCE-REGISTRY" "Tabela pipeline_evidence jest PUSTA (0 wierszy) — luka do naprawy, nie błąd pipeline'a"
  fi
else
  p_info "GOVERNANCE-REGISTRY" "sqlite3 lub baza niedostępna — pomijam kontrolę rejestrów (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$GAP_COUNT" -eq 0 ]; then
  p_pass "GOVERNANCE-FAIL-CLOSED-OK" BLOCKING "Wszystkie pipeline'y IMPLEMENTED mają istniejące skrypty"
else
  p_fail "GOVERNANCE-FAIL-CLOSED-GAP" BLOCKING "Znaleziono $GAP_COUNT pipeline'ów IMPLEMENTED bez skryptu"
fi
if [ "$BAD_STATUS_COUNT" -eq 0 ]; then
  p_pass "GOVERNANCE-STATUS-OK" BLOCKING "Wszystkie statusy pipeline'ów są spójne (IMPLEMENTED|PROPOSED)"
else
  p_fail "GOVERNANCE-STATUS-BAD" BLOCKING "Znaleziono $BAD_STATUS_COUNT nieprawidłowych statusów"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-039:pipeline-governance GAP=$GAP_COUNT BAD_STATUS=$BAD_STATUS_COUNT CONTRACT_REG_EMPTY=$CONTRACT_REG_EMPTY EVIDENCE_REG_EMPTY=$EVIDENCE_REG_EMPTY" "pipeline" "runtime/pipeline-governance.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$GAP_COUNT" -gt 0 ] || [ "$BAD_STATUS_COUNT" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-039" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-039" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
