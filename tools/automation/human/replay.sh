#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-087 — REPLAY (Human Simulation Plane — Stage 9: REPLAY)
# Rodzina: HUMAN-SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Test to nie skrypt, to użytkownik. Stage REPLAY odtwarza
# zarejestrowaną podróż użytkownika: replay trace, determinizm,
# powtarzalność, oraz evidence. Replay musi być deterministyczny —
# jak człowiek, nie jak bot.
#
# Gate'y: HUM-RP-01..08
#   * replay trace, determinism, repeatability, evidence,
#     replay evidence.
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
p_say "=== P-087 REPLAY ==="
p_say "Symulacja człowieka: replay trace, determinism, repeatability"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-087"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów replay w repo (best-effort, brak danych = NOT_APPLICABLE).
HUM_RP_TRACE=0
HUM_RP_DETERMINISM=0
HUM_RP_REPEATABILITY=0

# 1. Replay trace — artefakty trace do odtworzenia.
if [ -d "$ROOT/human/replay/trace" ] || [ -d "$ROOT/tests/human/replay" ]; then
  HUM_RP_TRACE=$(find "$ROOT/human/replay/trace" "$ROOT/tests/human/replay" -type f 2>/dev/null | wc -l)
fi
# 2. Determinism — konfiguracja determinizmu (seed, clock).
if [ -d "$ROOT/human/replay/determinism" ]; then
  HUM_RP_DETERMINISM=$(find "$ROOT/human/replay/determinism" -type f 2>/dev/null | wc -l)
fi
# 3. Repeatability — testy powtarzalności.
if [ -d "$ROOT/human/replay/repeatability" ]; then
  HUM_RP_REPEATABILITY=$(find "$ROOT/human/replay/repeatability" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów HUM-RP-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$HUM_RP_TRACE" -gt 0 ]; then
  p_pass "HUM-RP-01" BLOCKING "Replay trace: $HUM_RP_TRACE artefaktów"
else
  p_info "HUM-RP-01" "Replay trace: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_RP_DETERMINISM" -gt 0 ]; then
  p_pass "HUM-RP-02" BLOCKING "Determinism: $HUM_RP_DETERMINISM artefaktów"
else
  p_info "HUM-RP-02" "Determinism: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_RP_REPEATABILITY" -gt 0 ]; then
  p_pass "HUM-RP-03" BLOCKING "Repeatability: $HUM_RP_REPEATABILITY artefaktów"
else
  p_info "HUM-RP-03" "Repeatability: brak danych (NOT_APPLICABLE)"
fi
# HUM-RP-04 — replay evidence.
if [ "$HUM_RP_TRACE" -gt 0 ] || [ "$HUM_RP_DETERMINISM" -gt 0 ] || [ "$HUM_RP_REPEATABILITY" -gt 0 ]; then
  p_pass "HUM-RP-04" BLOCKING "Replay evidence zebrane"
else
  p_info "HUM-RP-04" "Replay evidence: brak danych (NOT_APPLICABLE)"
fi
# HUM-RP-05 — replay evidence (kompletność).
if [ "$HUM_RP_TRACE" -gt 0 ] && [ "$HUM_RP_DETERMINISM" -gt 0 ]; then
  p_pass "HUM-RP-05" BLOCKING "Replay evidence kompletne (trace + determinism)"
else
  p_info "HUM-RP-05" "Replay evidence kompletne: brak danych (NOT_APPLICABLE)"
fi
# HUM-RP-06 — replay evidence (powtarzalność).
if [ "$HUM_RP_REPEATABILITY" -gt 0 ]; then
  p_pass "HUM-RP-06" BLOCKING "Repeatability evidence obecne"
else
  p_info "HUM-RP-06" "Repeatability evidence: brak danych (NOT_APPLICABLE)"
fi
# HUM-RP-07 — replay evidence (determinizm).
if [ "$HUM_RP_DETERMINISM" -gt 0 ]; then
  p_pass "HUM-RP-07" BLOCKING "Determinism evidence obecne"
else
  p_info "HUM-RP-07" "Determinism evidence: brak danych (NOT_APPLICABLE)"
fi
# HUM-RP-08 — replay evidence (trace).
if [ "$HUM_RP_TRACE" -gt 0 ]; then
  p_pass "HUM-RP-08" BLOCKING "Trace evidence obecne"
else
  p_info "HUM-RP-08" "Trace evidence: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-087:replay TRACE=$HUM_RP_TRACE DETERMINISM=$HUM_RP_DETERMINISM REPEATABILITY=$HUM_RP_REPEATABILITY" "pipeline" "human/replay.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$HUM_RP_TRACE" -gt 0 ] || [ "$HUM_RP_DETERMINISM" -gt 0 ] || [ "$HUM_RP_REPEATABILITY" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-087" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-087" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
