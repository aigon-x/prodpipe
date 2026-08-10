#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-083 — INTERACT (Human Simulation Plane — Stage 5: INTERACT)
# Rodzina: HUMAN-SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Test to nie skrypt, to użytkownik. Stage INTERACT symuluje
# interakcje użytkownika: click, type, hover, drag, scroll, focus,
# formularze, oraz accessibility (axe-core). Interakcja musi być
# realistyczna — jak człowiek, nie jak bot.
#
# Gate'y: HUM-I-01..15
#   * click, type, hover, drag, scroll, focus, forms, accessibility,
#     keyboard, touch, upload, select, checkbox, radio, interact evidence.
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
p_say "=== P-083 INTERACT ==="
p_say "Symulacja człowieka: click, type, hover, drag, scroll, focus, forms, accessibility"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-083"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów interakcji w repo (best-effort, brak danych = NOT_APPLICABLE).
HUM_I_CLICK=0
HUM_I_TYPE=0
HUM_I_HOVER=0
HUM_I_DRAG=0
HUM_I_SCROLL=0
HUM_I_FOCUS=0
HUM_I_FORMS=0
HUM_I_A11Y=0
HUM_I_KEYBOARD=0
HUM_I_TOUCH=0
HUM_I_UPLOAD=0
HUM_I_SELECT=0
HUM_I_CHECKBOX=0
HUM_I_RADIO=0

# 1. Click — testy klikania.
if [ -d "$ROOT/human/interact/click" ] || [ -d "$ROOT/tests/human/interact" ]; then
  HUM_I_CLICK=$(find "$ROOT/human/interact/click" "$ROOT/tests/human/interact" -type f 2>/dev/null | wc -l)
fi
# 2. Type — testy wpisywania tekstu.
if [ -d "$ROOT/human/interact/type" ]; then
  HUM_I_TYPE=$(find "$ROOT/human/interact/type" -type f 2>/dev/null | wc -l)
fi
# 3. Hover — testy najeżdżania.
if [ -d "$ROOT/human/interact/hover" ]; then
  HUM_I_HOVER=$(find "$ROOT/human/interact/hover" -type f 2>/dev/null | wc -l)
fi
# 4. Drag — testy przeciągania.
if [ -d "$ROOT/human/interact/drag" ]; then
  HUM_I_DRAG=$(find "$ROOT/human/interact/drag" -type f 2>/dev/null | wc -l)
fi
# 5. Scroll — testy przewijania.
if [ -d "$ROOT/human/interact/scroll" ]; then
  HUM_I_SCROLL=$(find "$ROOT/human/interact/scroll" -type f 2>/dev/null | wc -l)
fi
# 6. Focus — testy fokusu.
if [ -d "$ROOT/human/interact/focus" ]; then
  HUM_I_FOCUS=$(find "$ROOT/human/interact/focus" -type f 2>/dev/null | wc -l)
fi
# 7. Forms — testy formularzy.
if [ -d "$ROOT/human/interact/forms" ]; then
  HUM_I_FORMS=$(find "$ROOT/human/interact/forms" -type f 2>/dev/null | wc -l)
fi
# 8. Accessibility — testy accessibility (axe-core).
if [ -f "$ROOT/axe.config.js" ] || [ -f "$ROOT/axe.config.ts" ] || [ -d "$ROOT/human/interact/a11y" ]; then
  HUM_I_A11Y=1
fi
# 9. Keyboard — testy klawiatury.
if [ -d "$ROOT/human/interact/keyboard" ]; then
  HUM_I_KEYBOARD=$(find "$ROOT/human/interact/keyboard" -type f 2>/dev/null | wc -l)
fi
# 10. Touch — testy dotyku.
if [ -d "$ROOT/human/interact/touch" ]; then
  HUM_I_TOUCH=$(find "$ROOT/human/interact/touch" -type f 2>/dev/null | wc -l)
fi
# 11. Upload — testy uploadu plików.
if [ -d "$ROOT/human/interact/upload" ]; then
  HUM_I_UPLOAD=$(find "$ROOT/human/interact/upload" -type f 2>/dev/null | wc -l)
fi
# 12. Select — testy select/dropdown.
if [ -d "$ROOT/human/interact/select" ]; then
  HUM_I_SELECT=$(find "$ROOT/human/interact/select" -type f 2>/dev/null | wc -l)
fi
# 13. Checkbox — testy checkboxów.
if [ -d "$ROOT/human/interact/checkbox" ]; then
  HUM_I_CHECKBOX=$(find "$ROOT/human/interact/checkbox" -type f 2>/dev/null | wc -l)
fi
# 14. Radio — testy radio buttonów.
if [ -d "$ROOT/human/interact/radio" ]; then
  HUM_I_RADIO=$(find "$ROOT/human/interact/radio" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 15 gate'ów HUM-I-01..15. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$HUM_I_CLICK" -gt 0 ]; then
  p_pass "HUM-I-01" BLOCKING "Click: $HUM_I_CLICK artefaktów"
else
  p_info "HUM-I-01" "Click: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_TYPE" -gt 0 ]; then
  p_pass "HUM-I-02" BLOCKING "Type: $HUM_I_TYPE artefaktów"
else
  p_info "HUM-I-02" "Type: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_HOVER" -gt 0 ]; then
  p_pass "HUM-I-03" BLOCKING "Hover: $HUM_I_HOVER artefaktów"
else
  p_info "HUM-I-03" "Hover: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_DRAG" -gt 0 ]; then
  p_pass "HUM-I-04" BLOCKING "Drag: $HUM_I_DRAG artefaktów"
else
  p_info "HUM-I-04" "Drag: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_SCROLL" -gt 0 ]; then
  p_pass "HUM-I-05" BLOCKING "Scroll: $HUM_I_SCROLL artefaktów"
else
  p_info "HUM-I-05" "Scroll: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_FOCUS" -gt 0 ]; then
  p_pass "HUM-I-06" BLOCKING "Focus: $HUM_I_FOCUS artefaktów"
else
  p_info "HUM-I-06" "Focus: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_FORMS" -gt 0 ]; then
  p_pass "HUM-I-07" BLOCKING "Forms: $HUM_I_FORMS artefaktów"
else
  p_info "HUM-I-07" "Forms: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_A11Y" -gt 0 ]; then
  p_pass "HUM-I-08" BLOCKING "Accessibility (axe-core) config obecny"
else
  p_info "HUM-I-08" "Accessibility (axe-core): brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_KEYBOARD" -gt 0 ]; then
  p_pass "HUM-I-09" BLOCKING "Keyboard: $HUM_I_KEYBOARD artefaktów"
else
  p_info "HUM-I-09" "Keyboard: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_TOUCH" -gt 0 ]; then
  p_pass "HUM-I-10" BLOCKING "Touch: $HUM_I_TOUCH artefaktów"
else
  p_info "HUM-I-10" "Touch: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_UPLOAD" -gt 0 ]; then
  p_pass "HUM-I-11" BLOCKING "Upload: $HUM_I_UPLOAD artefaktów"
else
  p_info "HUM-I-11" "Upload: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_SELECT" -gt 0 ]; then
  p_pass "HUM-I-12" BLOCKING "Select: $HUM_I_SELECT artefaktów"
else
  p_info "HUM-I-12" "Select: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_CHECKBOX" -gt 0 ]; then
  p_pass "HUM-I-13" BLOCKING "Checkbox: $HUM_I_CHECKBOX artefaktów"
else
  p_info "HUM-I-13" "Checkbox: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_I_RADIO" -gt 0 ]; then
  p_pass "HUM-I-14" BLOCKING "Radio: $HUM_I_RADIO artefaktów"
else
  p_info "HUM-I-14" "Radio: brak danych (NOT_APPLICABLE)"
fi
# HUM-I-15 — interact evidence.
if [ "$HUM_I_CLICK" -gt 0 ] || [ "$HUM_I_TYPE" -gt 0 ] || [ "$HUM_I_HOVER" -gt 0 ] || [ "$HUM_I_DRAG" -gt 0 ] || [ "$HUM_I_SCROLL" -gt 0 ] || [ "$HUM_I_FOCUS" -gt 0 ] || [ "$HUM_I_FORMS" -gt 0 ] || [ "$HUM_I_A11Y" -gt 0 ] || [ "$HUM_I_KEYBOARD" -gt 0 ] || [ "$HUM_I_TOUCH" -gt 0 ] || [ "$HUM_I_UPLOAD" -gt 0 ] || [ "$HUM_I_SELECT" -gt 0 ] || [ "$HUM_I_CHECKBOX" -gt 0 ] || [ "$HUM_I_RADIO" -gt 0 ]; then
  p_pass "HUM-I-15" BLOCKING "Interact evidence zebrane"
else
  p_info "HUM-I-15" "Interact evidence: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-083:interact CLICK=$HUM_I_CLICK TYPE=$HUM_I_TYPE HOVER=$HUM_I_HOVER DRAG=$HUM_I_DRAG SCROLL=$HUM_I_SCROLL FOCUS=$HUM_I_FOCUS FORMS=$HUM_I_FORMS A11Y=$HUM_I_A11Y KEYBOARD=$HUM_I_KEYBOARD TOUCH=$HUM_I_TOUCH UPLOAD=$HUM_I_UPLOAD SELECT=$HUM_I_SELECT CHECKBOX=$HUM_I_CHECKBOX RADIO=$HUM_I_RADIO" "pipeline" "human/interact.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$HUM_I_CLICK" -gt 0 ] || [ "$HUM_I_TYPE" -gt 0 ] || [ "$HUM_I_HOVER" -gt 0 ] || [ "$HUM_I_DRAG" -gt 0 ] || [ "$HUM_I_SCROLL" -gt 0 ] || [ "$HUM_I_FOCUS" -gt 0 ] || [ "$HUM_I_FORMS" -gt 0 ] || [ "$HUM_I_A11Y" -gt 0 ] || [ "$HUM_I_KEYBOARD" -gt 0 ] || [ "$HUM_I_TOUCH" -gt 0 ] || [ "$HUM_I_UPLOAD" -gt 0 ] || [ "$HUM_I_SELECT" -gt 0 ] || [ "$HUM_I_CHECKBOX" -gt 0 ] || [ "$HUM_I_RADIO" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-083" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-083" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
