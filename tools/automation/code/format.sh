#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-025 — FORMAT (Formatowanie kodu)
# Rodzina: CODE | Klasa: FAST | Status: IMPLEMENTED
#
# Weryfikuje, że repozytorium ma skonfigurowane formatowanie kodu.
# Wykrywa:
#   * NO-FORMAT-CONFIG — brak konfiguracji formatowania
#   * FORMAT-CONFIG    — obecna konfiguracja formatowania
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
p_say "=== P-025 FORMAT ==="
p_say "Weryfikacja konfiguracji formatowania kodu"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-025"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykryj konfiguracje formatowania dla popularnych narzędzi.
FORMAT_FILES="$(p_repo_files --name '(\.prettierrc|\.prettierrc\.|\.editorconfig|rustfmt\.toml|\.clang-format|\.gofmt|\.goimports|\.black|pyproject\.toml|\.terraform\.fmt|\.shfmt|\.stylua)')"
FORMAT_COUNT=$(printf '%s\n' "$FORMAT_FILES" | grep -c . || true)

# ── TEST ────────────────────────────────────────────────────
if [ "$FORMAT_COUNT" -gt 0 ]; then
  p_pass "FORMAT-CONFIG-PRESENT" BLOCKING "Znaleziono $FORMAT_COUNT konfiguracji formatowania"
else
  p_fail "FORMAT-CONFIG-MISSING" BLOCKING "Brak konfiguracji formatowania w repozytorium"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-025:format FORMAT_CONFIGS=$FORMAT_COUNT" "pipeline" "code/format.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$FORMAT_COUNT" -eq 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-025" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-025" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "FAST" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
