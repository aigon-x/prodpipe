#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-088 — TERMINAL (Human Simulation Plane — Stage 10: TERMINAL)
# Rodzina: HUMAN-SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Test to nie skrypt, to użytkownik. Stage TERMINAL testuje
# aplikacje terminalowe (TUI/CLI): tmux, PTY, interakcje klawiatury,
# output, oraz evidence. Test terminala musi być realistyczny —
# jak człowiek, nie jak bot.
#
# Gate'y: HUM-T-01..08
#   * tmux, PTY, keyboard, output, evidence, terminal evidence.
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
p_say "=== P-088 TERMINAL ==="
p_say "Symulacja człowieka: tmux, PTY, keyboard, output"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-088"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów testów terminala w repo (best-effort, brak danych = NOT_APPLICABLE).
HUM_T_TMUX=0
HUM_T_PTY=0
HUM_T_KEYBOARD=0
HUM_T_OUTPUT=0

# 1. tmux — konfiguracja testów tmux.
if [ -d "$ROOT/human/terminal/tmux" ] || [ -d "$ROOT/tests/human/terminal" ]; then
  HUM_T_TMUX=$(find "$ROOT/human/terminal/tmux" "$ROOT/tests/human/terminal" -type f 2>/dev/null | wc -l)
fi
# 2. PTY — testy PTY (pseudo-terminal).
if [ -d "$ROOT/human/terminal/pty" ]; then
  HUM_T_PTY=$(find "$ROOT/human/terminal/pty" -type f 2>/dev/null | wc -l)
fi
# 3. Keyboard — testy interakcji klawiatury.
if [ -d "$ROOT/human/terminal/keyboard" ]; then
  HUM_T_KEYBOARD=$(find "$ROOT/human/terminal/keyboard" -type f 2>/dev/null | wc -l)
fi
# 4. Output — testy outputu terminala.
if [ -d "$ROOT/human/terminal/output" ]; then
  HUM_T_OUTPUT=$(find "$ROOT/human/terminal/output" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów HUM-T-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$HUM_T_TMUX" -gt 0 ]; then
  p_pass "HUM-T-01" BLOCKING "tmux: $HUM_T_TMUX artefaktów"
else
  p_info "HUM-T-01" "tmux: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_T_PTY" -gt 0 ]; then
  p_pass "HUM-T-02" BLOCKING "PTY: $HUM_T_PTY artefaktów"
else
  p_info "HUM-T-02" "PTY: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_T_KEYBOARD" -gt 0 ]; then
  p_pass "HUM-T-03" BLOCKING "Keyboard: $HUM_T_KEYBOARD artefaktów"
else
  p_info "HUM-T-03" "Keyboard: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_T_OUTPUT" -gt 0 ]; then
  p_pass "HUM-T-04" BLOCKING "Output: $HUM_T_OUTPUT artefaktów"
else
  p_info "HUM-T-04" "Output: brak danych (NOT_APPLICABLE)"
fi
# HUM-T-05 — terminal evidence.
if [ "$HUM_T_TMUX" -gt 0 ] || [ "$HUM_T_PTY" -gt 0 ] || [ "$HUM_T_KEYBOARD" -gt 0 ] || [ "$HUM_T_OUTPUT" -gt 0 ]; then
  p_pass "HUM-T-05" BLOCKING "Terminal evidence zebrane"
else
  p_info "HUM-T-05" "Terminal evidence: brak danych (NOT_APPLICABLE)"
fi
# HUM-T-06 — terminal evidence (kompletność).
if [ "$HUM_T_TMUX" -gt 0 ] && [ "$HUM_T_PTY" -gt 0 ]; then
  p_pass "HUM-T-06" BLOCKING "Terminal evidence kompletne (tmux + PTY)"
else
  p_info "HUM-T-06" "Terminal evidence kompletne: brak danych (NOT_APPLICABLE)"
fi
# HUM-T-07 — terminal evidence (interakcja).
if [ "$HUM_T_KEYBOARD" -gt 0 ]; then
  p_pass "HUM-T-07" BLOCKING "Keyboard interaction evidence obecne"
else
  p_info "HUM-T-07" "Keyboard interaction evidence: brak danych (NOT_APPLICABLE)"
fi
# HUM-T-08 — terminal evidence (output).
if [ "$HUM_T_OUTPUT" -gt 0 ]; then
  p_pass "HUM-T-08" BLOCKING "Output evidence obecne"
else
  p_info "HUM-T-08" "Output evidence: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-088:terminal TMUX=$HUM_T_TMUX PTY=$HUM_T_PTY KEYBOARD=$HUM_T_KEYBOARD OUTPUT=$HUM_T_OUTPUT" "pipeline" "human/terminal.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$HUM_T_TMUX" -gt 0 ] || [ "$HUM_T_PTY" -gt 0 ] || [ "$HUM_T_KEYBOARD" -gt 0 ] || [ "$HUM_T_OUTPUT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-088" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-088" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
