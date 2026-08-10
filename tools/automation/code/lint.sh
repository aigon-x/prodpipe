#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-024 — LINT (Statyczna analiza kodu)
# Rodzina: CODE | Klasa: FAST | Status: IMPLEMENTED
#
# Weryfikuje, że repozytorium ma skonfigurowany lint (statyczną analizę
# kodu). Wykrywa:
#   * NO-LINT-CONFIG — brak konfiguracji lint dla żadnego języka
#   * LINT-CONFIG    — obecna konfiguracja lint
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
p_say "=== P-024 LINT ==="
p_say "Weryfikacja konfiguracji statycznej analizy kodu (lint)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-024"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykryj konfiguracje lint dla popularnych języków/narzędzi.
LINT_FILES="$(p_repo_files --name '(\.eslintrc|\.eslintrc\.|\.golangci|ruff\.toml|\.flake8|pyproject\.toml|\.shellcheckrc|shellcheck|\.clang-format|\.clang-tidy|\.rubocop|\.stylelintrc|\.yamllint|\.markdownlint)')"
LINT_COUNT=$(printf '%s\n' "$LINT_FILES" | grep -c . || true)

# ── TEST ────────────────────────────────────────────────────
if [ "$LINT_COUNT" -gt 0 ]; then
  p_pass "LINT-CONFIG-PRESENT" BLOCKING "Znaleziono $LINT_COUNT konfiguracji lint"
else
  p_fail "LINT-CONFIG-MISSING" BLOCKING "Brak konfiguracji lint w repozytorium"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-024:lint LINT_CONFIGS=$LINT_COUNT" "pipeline" "code/lint.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# repo_verdict odzwierciedla wynik checka BLOCKING: brak konfiguracji lint = FAIL.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$LINT_COUNT" -eq 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-024" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-024" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "FAST" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
