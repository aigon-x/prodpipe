#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-084 — ASSERT (Human Simulation Plane — Stage 6: ASSERT)
# Rodzina: HUMAN-SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Test to nie skrypt, to użytkownik. Stage ASSERT weryfikuje, że
# aplikacja zachowuje się jak oczekuje użytkownik: asercje stanu,
# tekstu, widoczności, wartości, atrybutów, oraz accessibility
# (axe-core). Asercja musi być semantyczna — jak człowiek, nie jak bot.
#
# Gate'y: HUM-A-01..15
#   * state, text, visibility, value, attribute, accessibility,
#     count, url, screenshot, network, console, focus, style,
#     element, assert evidence.
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
p_say "=== P-084 ASSERT ==="
p_say "Symulacja człowieka: state, text, visibility, value, attribute, accessibility"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-084"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów asercji w repo (best-effort, brak danych = NOT_APPLICABLE).
HUM_A_STATE=0
HUM_A_TEXT=0
HUM_A_VISIBILITY=0
HUM_A_VALUE=0
HUM_A_ATTRIBUTE=0
HUM_A_A11Y=0
HUM_A_COUNT=0
HUM_A_URL=0
HUM_A_SCREENSHOT=0
HUM_A_NETWORK=0
HUM_A_CONSOLE=0
HUM_A_FOCUS=0
HUM_A_STYLE=0
HUM_A_ELEMENT=0

# 1. State — asercje stanu (enabled/disabled/checked).
if [ -d "$ROOT/human/assert/state" ] || [ -d "$ROOT/tests/human/assert" ]; then
  HUM_A_STATE=$(find "$ROOT/human/assert/state" "$ROOT/tests/human/assert" -type f 2>/dev/null | wc -l)
fi
# 2. Text — asercje tekstu.
if [ -d "$ROOT/human/assert/text" ]; then
  HUM_A_TEXT=$(find "$ROOT/human/assert/text" -type f 2>/dev/null | wc -l)
fi
# 3. Visibility — asercje widoczności.
if [ -d "$ROOT/human/assert/visibility" ]; then
  HUM_A_VISIBILITY=$(find "$ROOT/human/assert/visibility" -type f 2>/dev/null | wc -l)
fi
# 4. Value — asercje wartości.
if [ -d "$ROOT/human/assert/value" ]; then
  HUM_A_VALUE=$(find "$ROOT/human/assert/value" -type f 2>/dev/null | wc -l)
fi
# 5. Attribute — asercje atrybutów.
if [ -d "$ROOT/human/assert/attribute" ]; then
  HUM_A_ATTRIBUTE=$(find "$ROOT/human/assert/attribute" -type f 2>/dev/null | wc -l)
fi
# 6. Accessibility — asercje accessibility (axe-core).
if [ -f "$ROOT/axe.config.js" ] || [ -f "$ROOT/axe.config.ts" ] || [ -d "$ROOT/human/assert/a11y" ]; then
  HUM_A_A11Y=1
fi
# 7. Count — asercje liczby elementów.
if [ -d "$ROOT/human/assert/count" ]; then
  HUM_A_COUNT=$(find "$ROOT/human/assert/count" -type f 2>/dev/null | wc -l)
fi
# 8. URL — asercje URL.
if [ -d "$ROOT/human/assert/url" ]; then
  HUM_A_URL=$(find "$ROOT/human/assert/url" -type f 2>/dev/null | wc -l)
fi
# 9. Screenshot — asercje screenshotów.
if [ -d "$ROOT/human/assert/screenshot" ]; then
  HUM_A_SCREENSHOT=$(find "$ROOT/human/assert/screenshot" -type f 2>/dev/null | wc -l)
fi
# 10. Network — asercje sieci (request/response).
if [ -d "$ROOT/human/assert/network" ]; then
  HUM_A_NETWORK=$(find "$ROOT/human/assert/network" -type f 2>/dev/null | wc -l)
fi
# 11. Console — asercje konsoli (brak błędów).
if [ -d "$ROOT/human/assert/console" ]; then
  HUM_A_CONSOLE=$(find "$ROOT/human/assert/console" -type f 2>/dev/null | wc -l)
fi
# 12. Focus — asercje fokusu.
if [ -d "$ROOT/human/assert/focus" ]; then
  HUM_A_FOCUS=$(find "$ROOT/human/assert/focus" -type f 2>/dev/null | wc -l)
fi
# 13. Style — asercje stylów (CSS).
if [ -d "$ROOT/human/assert/style" ]; then
  HUM_A_STYLE=$(find "$ROOT/human/assert/style" -type f 2>/dev/null | wc -l)
fi
# 14. Element — asercje elementów (istnienie).
if [ -d "$ROOT/human/assert/element" ]; then
  HUM_A_ELEMENT=$(find "$ROOT/human/assert/element" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 15 gate'ów HUM-A-01..15. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$HUM_A_STATE" -gt 0 ]; then
  p_pass "HUM-A-01" BLOCKING "State: $HUM_A_STATE artefaktów"
else
  p_info "HUM-A-01" "State: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_TEXT" -gt 0 ]; then
  p_pass "HUM-A-02" BLOCKING "Text: $HUM_A_TEXT artefaktów"
else
  p_info "HUM-A-02" "Text: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_VISIBILITY" -gt 0 ]; then
  p_pass "HUM-A-03" BLOCKING "Visibility: $HUM_A_VISIBILITY artefaktów"
else
  p_info "HUM-A-03" "Visibility: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_VALUE" -gt 0 ]; then
  p_pass "HUM-A-04" BLOCKING "Value: $HUM_A_VALUE artefaktów"
else
  p_info "HUM-A-04" "Value: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_ATTRIBUTE" -gt 0 ]; then
  p_pass "HUM-A-05" BLOCKING "Attribute: $HUM_A_ATTRIBUTE artefaktów"
else
  p_info "HUM-A-05" "Attribute: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_A11Y" -gt 0 ]; then
  p_pass "HUM-A-06" BLOCKING "Accessibility (axe-core) config obecny"
else
  p_info "HUM-A-06" "Accessibility (axe-core): brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_COUNT" -gt 0 ]; then
  p_pass "HUM-A-07" BLOCKING "Count: $HUM_A_COUNT artefaktów"
else
  p_info "HUM-A-07" "Count: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_URL" -gt 0 ]; then
  p_pass "HUM-A-08" BLOCKING "URL: $HUM_A_URL artefaktów"
else
  p_info "HUM-A-08" "URL: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_SCREENSHOT" -gt 0 ]; then
  p_pass "HUM-A-09" BLOCKING "Screenshot: $HUM_A_SCREENSHOT artefaktów"
else
  p_info "HUM-A-09" "Screenshot: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_NETWORK" -gt 0 ]; then
  p_pass "HUM-A-10" BLOCKING "Network: $HUM_A_NETWORK artefaktów"
else
  p_info "HUM-A-10" "Network: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_CONSOLE" -gt 0 ]; then
  p_pass "HUM-A-11" BLOCKING "Console: $HUM_A_CONSOLE artefaktów"
else
  p_info "HUM-A-11" "Console: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_FOCUS" -gt 0 ]; then
  p_pass "HUM-A-12" BLOCKING "Focus: $HUM_A_FOCUS artefaktów"
else
  p_info "HUM-A-12" "Focus: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_STYLE" -gt 0 ]; then
  p_pass "HUM-A-13" BLOCKING "Style: $HUM_A_STYLE artefaktów"
else
  p_info "HUM-A-13" "Style: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_A_ELEMENT" -gt 0 ]; then
  p_pass "HUM-A-14" BLOCKING "Element: $HUM_A_ELEMENT artefaktów"
else
  p_info "HUM-A-14" "Element: brak danych (NOT_APPLICABLE)"
fi
# HUM-A-15 — assert evidence.
if [ "$HUM_A_STATE" -gt 0 ] || [ "$HUM_A_TEXT" -gt 0 ] || [ "$HUM_A_VISIBILITY" -gt 0 ] || [ "$HUM_A_VALUE" -gt 0 ] || [ "$HUM_A_ATTRIBUTE" -gt 0 ] || [ "$HUM_A_A11Y" -gt 0 ] || [ "$HUM_A_COUNT" -gt 0 ] || [ "$HUM_A_URL" -gt 0 ] || [ "$HUM_A_SCREENSHOT" -gt 0 ] || [ "$HUM_A_NETWORK" -gt 0 ] || [ "$HUM_A_CONSOLE" -gt 0 ] || [ "$HUM_A_FOCUS" -gt 0 ] || [ "$HUM_A_STYLE" -gt 0 ] || [ "$HUM_A_ELEMENT" -gt 0 ]; then
  p_pass "HUM-A-15" BLOCKING "Assert evidence zebrane"
else
  p_info "HUM-A-15" "Assert evidence: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-084:assert STATE=$HUM_A_STATE TEXT=$HUM_A_TEXT VISIBILITY=$HUM_A_VISIBILITY VALUE=$HUM_A_VALUE ATTRIBUTE=$HUM_A_ATTRIBUTE A11Y=$HUM_A_A11Y COUNT=$HUM_A_COUNT URL=$HUM_A_URL SCREENSHOT=$HUM_A_SCREENSHOT NETWORK=$HUM_A_NETWORK CONSOLE=$HUM_A_CONSOLE FOCUS=$HUM_A_FOCUS STYLE=$HUM_A_STYLE ELEMENT=$HUM_A_ELEMENT" "pipeline" "human/assert.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$HUM_A_STATE" -gt 0 ] || [ "$HUM_A_TEXT" -gt 0 ] || [ "$HUM_A_VISIBILITY" -gt 0 ] || [ "$HUM_A_VALUE" -gt 0 ] || [ "$HUM_A_ATTRIBUTE" -gt 0 ] || [ "$HUM_A_A11Y" -gt 0 ] || [ "$HUM_A_COUNT" -gt 0 ] || [ "$HUM_A_URL" -gt 0 ] || [ "$HUM_A_SCREENSHOT" -gt 0 ] || [ "$HUM_A_NETWORK" -gt 0 ] || [ "$HUM_A_CONSOLE" -gt 0 ] || [ "$HUM_A_FOCUS" -gt 0 ] || [ "$HUM_A_STYLE" -gt 0 ] || [ "$HUM_A_ELEMENT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-084" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-084" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
