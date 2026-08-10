#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-006 — BACKLOG (Product Backlog)
# Rodzina: PRODUCT | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje istnienie backlogu produktu: wymagania w statusach
# backlogowych (IDEA/DISCOVERING/DEFINED) oraz brak wymagań
# "zagubionych" (bez statusu / bez przypisania do backlogu).
#
# Wykrywa:
#   * NO-BACKLOG      — brak wymagań w statusach backlogowych
#   * REQ-NO-STATUS   — wymaganie bez statusu (nieprzypisane do backlogu)
#   * REQ-UNKNOWN-STATUS — wymaganie z nieznanym statusem
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
p_say "=== P-006 BACKLOG ==="
p_say "Weryfikacja backlogu produktu (wymagania w statusach backlogowych)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-006"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
TOTAL=0
BACKLOG=0
NO_STATUS=0
UNKNOWN_STATUS=0
DB_OK=0

# Statusy uznawane za "backlog" (wczesne fazy lifecycle'u wymagania).
BACKLOG_STATUSES="'IDEA','DISCOVERING','DEFINED'"

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_OK=1
  TOTAL=$(sqlite3 "$db" "SELECT COUNT(*) FROM requirement;" 2>/dev/null || echo 0)
  # 1. Wymagania w statusach backlogowych.
  BACKLOG=$(sqlite3 "$db" "SELECT COUNT(*) FROM requirement WHERE UPPER(status) IN ($BACKLOG_STATUSES);" 2>/dev/null || echo 0)
  # 2. Wymaganie bez statusu (nieprzypisane do backlogu).
  NO_STATUS=$(sqlite3 "$db" "SELECT COUNT(*) FROM requirement WHERE status IS NULL OR status = '';" 2>/dev/null || echo 0)
  # 3. Wymaganie z nieznanym statusem (poza dozwolonym lifecycle'em).
  UNKNOWN_STATUS=$(sqlite3 "$db" "SELECT COUNT(*) FROM requirement WHERE status IS NOT NULL AND status != '' AND UPPER(status) NOT IN ('IDEA','DISCOVERING','DEFINED','CONTRACTED','DESIGNED','IMPLEMENTING','VERIFYING','INTEGRATING','HARDENING','RELEASING','STAGING','CERTIFIED','CANARY','PRODUCTION','OPERATING','DEPRECATED','RETIRED','BLOCKED');" 2>/dev/null || echo 0)
else
  p_info "BACKLOG-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_OK" -eq 0 ]; then
  p_info "BACKLOG-NO-DB" "Brak danych StateStore — repo_verdict NOT_APPLICABLE"
elif [ "$TOTAL" -eq 0 ]; then
  p_info "BACKLOG-EMPTY" "Brak wymagań w StateStore — repo_verdict NOT_APPLICABLE"
else
  if [ "$BACKLOG" -gt 0 ]; then
    p_pass "BACKLOG-HAS-ITEMS" BLOCKING "Znaleziono $BACKLOG wymagań w backlogu (statusy IDEA/DISCOVERING/DEFINED)"
  else
    p_fail "BACKLOG-NO-BACKLOG" BLOCKING "Brak wymagań w statusach backlogowych — brak backlogu"
  fi
  if [ "$NO_STATUS" -eq 0 ]; then
    p_pass "BACKLOG-ALL-ASSIGNED" BLOCKING "Wszystkie wymagania mają status (przypisane do backlogu)"
  else
    p_fail "BACKLOG-REQ-NO-STATUS" BLOCKING "Znaleziono $NO_STATUS wymagań bez statusu (nieprzypisanych do backlogu)"
  fi
  if [ "$UNKNOWN_STATUS" -eq 0 ]; then
    p_pass "BACKLOG-ALL-KNOWN-STATUS" BLOCKING "Wszystkie statusy wymagań są z dozwolonego lifecycle'u"
  else
    p_warn "BACKLOG-REQ-UNKNOWN-STATUS" "Znaleziono $UNKNOWN_STATUS wymagań z nieznanym statusem"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-006:backlog TOTAL=$TOTAL BACKLOG=$BACKLOG NO_STATUS=$NO_STATUS UNKNOWN_STATUS=$UNKNOWN_STATUS" "pipeline" "product/backlog.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DB_OK" -eq 0 ] || [ "$TOTAL" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$BACKLOG" -eq 0 ] || [ "$NO_STATUS" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-006" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-006" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
