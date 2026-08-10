#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-050 — DOCUMENTATION (Documentation Existence & Freshness)
# Rodzina: RUNTIME | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje, że dokumentacja istnieje i jest aktualna:
#   * DOC-EXISTENCE   — wymagane dokumenty istnieją (README.md, ARCHITECTURE.md, DEPLOYMENT.md, RECOVERY.md)
#   * DOC-FRESHNESS   — dokumenty nie są nieaktualne (nie starsze niż próg dni)
#   * DOC-NONEMPTY    — dokumenty nie są puste (mają treść)
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
p_say "=== P-050 DOCUMENTATION ==="
p_say "Weryfikacja istnienia i aktualności dokumentacji (README, ARCHITECTURE, DEPLOYMENT, RECOVERY)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-050"

# ── EXECUTE ─────────────────────────────────────────────────
# Wymagane dokumenty na poziomie repo root.
DOCS="README.md ARCHITECTURE.md DEPLOYMENT.md RECOVERY.md"
# Próg świeżości w dniach (0 = wyłączone).
STALE_DAYS="${PIPE_DOC_STALE_DAYS:-180}"

MISSING=0
STALE=0
EMPTY=0
PRESENT=0

for doc in $DOCS; do
  path="$ROOT/$doc"
  if [ ! -f "$path" ]; then
    MISSING=$((MISSING + 1))
    p_fail "DOC-EXISTENCE: $doc" BLOCKING "Brak wymaganego dokumentu: $doc"
    continue
  fi
  PRESENT=$((PRESENT + 1))

  # DOC-NONEMPTY — dokument ma treść (nie jest pusty).
  if [ ! -s "$path" ]; then
    EMPTY=$((EMPTY + 1))
    p_fail "DOC-NONEMPTY: $doc" BLOCKING "Dokument $doc jest pusty"
  fi

  # DOC-FRESHNESS — dokument nie jest starszy niż próg dni.
  if [ "$STALE_DAYS" -gt 0 ]; then
    age_days=0
    if command -v stat >/dev/null 2>&1; then
      mtime="$(stat -c %Y "$path" 2>/dev/null || stat -f %m "$path" 2>/dev/null || echo 0)"
      now="$(date +%s)"
      if [ "${mtime:-0}" -gt 0 ]; then
        age_days=$(( (now - mtime) / 86400 ))
      fi
    fi
    if [ "$age_days" -gt "$STALE_DAYS" ]; then
      STALE=$((STALE + 1))
      p_fail "DOC-FRESHNESS: $doc" BLOCKING "Dokument $doc jest nieaktualny (wiek $age_days dni > próg $STALE_DAYS)"
    fi
  fi
done

# ── TEST ────────────────────────────────────────────────────
if [ "$MISSING" -eq 0 ]; then
  p_pass "DOC-EXISTENCE" BLOCKING "Wszystkie wymagane dokumenty istnieją ($PRESENT/$PRESENT)"
fi
if [ "$EMPTY" -eq 0 ]; then
  p_pass "DOC-NONEMPTY" BLOCKING "Wszystkie obecne dokumenty mają treść"
fi
if [ "$STALE_DAYS" -gt 0 ] && [ "$STALE" -eq 0 ]; then
  p_pass "DOC-FRESHNESS" BLOCKING "Wszystkie dokumenty są aktualne (próg $STALE_DAYS dni)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-050:documentation PRESENT=$PRESENT MISSING=$MISSING EMPTY=$EMPTY STALE=$STALE" "pipeline" "runtime/documentation.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$MISSING" -gt 0 ] || [ "$EMPTY" -gt 0 ] || [ "$STALE" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-050" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-050" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
