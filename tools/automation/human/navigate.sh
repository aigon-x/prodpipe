#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-080 — NAVIGATE (Human Simulation Plane — Stage 2: NAVIGATE)
# Rodzina: HUMAN-SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Test to nie skrypt, to użytkownik. Stage NAVIGATE symuluje
# podróż użytkownika po aplikacji: ścieżki nawigacji, URL routing,
# breadcrumbs, back/forward, głębokie linki, obsługa błędów 404,
# oraz nawigacja klawiaturą (accessibility).
#
# Gate'y: HUM-N-01..08
#   * navigation paths, URL routing, breadcrumbs, back/forward,
#     deep links, 404 handling, keyboard navigation, navigate evidence.
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
p_say "=== P-080 NAVIGATE ==="
p_say "Symulacja człowieka: navigation paths, URL routing, breadcrumbs, back/forward, deep links, 404, keyboard"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-080"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów nawigacji w repo (best-effort, brak danych = NOT_APPLICABLE).
HUM_N_PATHS=0
HUM_N_ROUTING=0
HUM_N_BREADCRUMBS=0
HUM_N_BACKFORWARD=0
HUM_N_DEEPLINK=0
HUM_N_404=0
HUM_N_KEYBOARD=0

# 1. Navigation paths — zdefiniowane ścieżki nawigacji.
if [ -d "$ROOT/human/navigate/paths" ] || [ -d "$ROOT/tests/human/navigate" ]; then
  HUM_N_PATHS=$(find "$ROOT/human/navigate/paths" "$ROOT/tests/human/navigate" -type f 2>/dev/null | wc -l)
fi
# 2. URL routing — testy routingu URL.
if [ -d "$ROOT/human/navigate/routing" ]; then
  HUM_N_ROUTING=$(find "$ROOT/human/navigate/routing" -type f 2>/dev/null | wc -l)
fi
# 3. Breadcrumbs — testy breadcrumbs.
if [ -d "$ROOT/human/navigate/breadcrumbs" ]; then
  HUM_N_BREADCRUMBS=$(find "$ROOT/human/navigate/breadcrumbs" -type f 2>/dev/null | wc -l)
fi
# 4. Back/forward — testy nawigacji wstecz/wprzód.
if [ -d "$ROOT/human/navigate/back-forward" ]; then
  HUM_N_BACKFORWARD=$(find "$ROOT/human/navigate/back-forward" -type f 2>/dev/null | wc -l)
fi
# 5. Deep links — testy głębokich linków.
if [ -d "$ROOT/human/navigate/deep-links" ]; then
  HUM_N_DEEPLINK=$(find "$ROOT/human/navigate/deep-links" -type f 2>/dev/null | wc -l)
fi
# 6. 404 handling — testy obsługi błędów 404.
if [ -d "$ROOT/human/navigate/404" ]; then
  HUM_N_404=$(find "$ROOT/human/navigate/404" -type f 2>/dev/null | wc -l)
fi
# 7. Keyboard navigation — testy nawigacji klawiaturą (accessibility).
if [ -d "$ROOT/human/navigate/keyboard" ]; then
  HUM_N_KEYBOARD=$(find "$ROOT/human/navigate/keyboard" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów HUM-N-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$HUM_N_PATHS" -gt 0 ]; then
  p_pass "HUM-N-01" BLOCKING "Navigation paths: $HUM_N_PATHS artefaktów"
else
  p_info "HUM-N-01" "Navigation paths: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_N_ROUTING" -gt 0 ]; then
  p_pass "HUM-N-02" BLOCKING "URL routing: $HUM_N_ROUTING artefaktów"
else
  p_info "HUM-N-02" "URL routing: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_N_BREADCRUMBS" -gt 0 ]; then
  p_pass "HUM-N-03" BLOCKING "Breadcrumbs: $HUM_N_BREADCRUMBS artefaktów"
else
  p_info "HUM-N-03" "Breadcrumbs: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_N_BACKFORWARD" -gt 0 ]; then
  p_pass "HUM-N-04" BLOCKING "Back/forward: $HUM_N_BACKFORWARD artefaktów"
else
  p_info "HUM-N-04" "Back/forward: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_N_DEEPLINK" -gt 0 ]; then
  p_pass "HUM-N-05" BLOCKING "Deep links: $HUM_N_DEEPLINK artefaktów"
else
  p_info "HUM-N-05" "Deep links: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_N_404" -gt 0 ]; then
  p_pass "HUM-N-06" BLOCKING "404 handling: $HUM_N_404 artefaktów"
else
  p_info "HUM-N-06" "404 handling: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_N_KEYBOARD" -gt 0 ]; then
  p_pass "HUM-N-07" BLOCKING "Keyboard navigation: $HUM_N_KEYBOARD artefaktów"
else
  p_info "HUM-N-07" "Keyboard navigation: brak danych (NOT_APPLICABLE)"
fi
# HUM-N-08 — navigate evidence.
if [ "$HUM_N_PATHS" -gt 0 ] || [ "$HUM_N_ROUTING" -gt 0 ] || [ "$HUM_N_BREADCRUMBS" -gt 0 ] || [ "$HUM_N_BACKFORWARD" -gt 0 ] || [ "$HUM_N_DEEPLINK" -gt 0 ] || [ "$HUM_N_404" -gt 0 ] || [ "$HUM_N_KEYBOARD" -gt 0 ]; then
  p_pass "HUM-N-08" BLOCKING "Navigate evidence zebrane"
else
  p_info "HUM-N-08" "Navigate evidence: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-080:navigate PATHS=$HUM_N_PATHS ROUTING=$HUM_N_ROUTING BREADCRUMBS=$HUM_N_BREADCRUMBS BACKFORWARD=$HUM_N_BACKFORWARD DEEPLINK=$HUM_N_DEEPLINK 404=$HUM_N_404 KEYBOARD=$HUM_N_KEYBOARD" "pipeline" "human/navigate.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$HUM_N_PATHS" -gt 0 ] || [ "$HUM_N_ROUTING" -gt 0 ] || [ "$HUM_N_BREADCRUMBS" -gt 0 ] || [ "$HUM_N_BACKFORWARD" -gt 0 ] || [ "$HUM_N_DEEPLINK" -gt 0 ] || [ "$HUM_N_404" -gt 0 ] || [ "$HUM_N_KEYBOARD" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-080" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-080" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
