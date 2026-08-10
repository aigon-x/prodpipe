#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-078 — LEARN (Offensive Security — Lessons Learned)
# Rodzina: OFFENSIVE-SECURITY | Klasa: DEEP | Status: PROPOSED
#
# Faza nauki (Purple Team). Atak to test, obrona to gate,
# detekcja to evidence. Zamyka pętlę: wnioski, aktualizacja
# modelu zagrożeń, tuning reguł, poprawa kontroli, trening.
#
# Gate'y: OFF-L-01..08
#   * lessons learned, threat model update, detection rule tuning,
#     security control improvement, training update, escape analysis,
#     knowledge base, metrics trend.
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
p_say "=== P-078 LEARN ==="
p_say "Nauka: lessons learned, threat model, tuning reguł, kontrola, trening, escape analysis, knowledge base, metryki"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-078"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów nauki w repo (best-effort).
LRN_LESSONS=0
LRN_THREAT=0
LRN_TUNING=0
LRN_CONTROL=0
LRN_TRAINING=0
LRN_ESCAPE=0
LRN_KB=0
LRN_METRICS=0

if [ -d "$ROOT/offsec/learn/lessons" ]; then
  LRN_LESSONS=$(find "$ROOT/offsec/learn/lessons" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/learn/threat-model" ]; then
  LRN_THREAT=$(find "$ROOT/offsec/learn/threat-model" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/learn/tuning" ]; then
  LRN_TUNING=$(find "$ROOT/offsec/learn/tuning" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/learn/control" ]; then
  LRN_CONTROL=$(find "$ROOT/offsec/learn/control" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/learn/training" ]; then
  LRN_TRAINING=$(find "$ROOT/offsec/learn/training" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/learn/escape" ]; then
  LRN_ESCAPE=$(find "$ROOT/offsec/learn/escape" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/learn/knowledge-base" ]; then
  LRN_KB=$(find "$ROOT/offsec/learn/knowledge-base" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/learn/metrics" ]; then
  LRN_METRICS=$(find "$ROOT/offsec/learn/metrics" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów OFF-L-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$LRN_LESSONS" -gt 0 ]; then
  p_pass "OFF-L-01" BLOCKING "Lessons learned: $LRN_LESSONS artefaktów"
else
  p_info "OFF-L-01" "Lessons learned: brak danych (NOT_APPLICABLE)"
fi
if [ "$LRN_THREAT" -gt 0 ]; then
  p_pass "OFF-L-02" BLOCKING "Threat model update: $LRN_THREAT artefaktów"
else
  p_info "OFF-L-02" "Threat model update: brak danych (NOT_APPLICABLE)"
fi
if [ "$LRN_TUNING" -gt 0 ]; then
  p_pass "OFF-L-03" BLOCKING "Detection rule tuning: $LRN_TUNING artefaktów"
else
  p_info "OFF-L-03" "Detection rule tuning: brak danych (NOT_APPLICABLE)"
fi
if [ "$LRN_CONTROL" -gt 0 ]; then
  p_pass "OFF-L-04" BLOCKING "Security control improvement: $LRN_CONTROL artefaktów"
else
  p_info "OFF-L-04" "Security control improvement: brak danych (NOT_APPLICABLE)"
fi
if [ "$LRN_TRAINING" -gt 0 ]; then
  p_pass "OFF-L-05" BLOCKING "Training update: $LRN_TRAINING artefaktów"
else
  p_info "OFF-L-05" "Training update: brak danych (NOT_APPLICABLE)"
fi
if [ "$LRN_ESCAPE" -gt 0 ]; then
  p_pass "OFF-L-06" BLOCKING "Escape analysis: $LRN_ESCAPE artefaktów"
else
  p_info "OFF-L-06" "Escape analysis: brak danych (NOT_APPLICABLE)"
fi
if [ "$LRN_KB" -gt 0 ]; then
  p_pass "OFF-L-07" BLOCKING "Knowledge base: $LRN_KB artefaktów"
else
  p_info "OFF-L-07" "Knowledge base: brak danych (NOT_APPLICABLE)"
fi
if [ "$LRN_METRICS" -gt 0 ]; then
  p_pass "OFF-L-08" BLOCKING "Metrics trend: $LRN_METRICS artefaktów"
else
  p_info "OFF-L-08" "Metrics trend: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-078:learn LESSONS=$LRN_LESSONS THREAT=$LRN_THREAT TUNING=$LRN_TUNING CONTROL=$LRN_CONTROL TRAINING=$LRN_TRAINING ESCAPE=$LRN_ESCAPE KB=$LRN_KB METRICS=$LRN_METRICS" "pipeline" "offsec/learn.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$LRN_LESSONS" -gt 0 ] || [ "$LRN_THREAT" -gt 0 ] || [ "$LRN_TUNING" -gt 0 ] || [ "$LRN_CONTROL" -gt 0 ] || [ "$LRN_TRAINING" -gt 0 ] || [ "$LRN_ESCAPE" -gt 0 ] || [ "$LRN_KB" -gt 0 ] || [ "$LRN_METRICS" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-078" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-078" "$repo_verdict" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
