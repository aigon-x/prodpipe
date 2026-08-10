#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-016 — SECRETS (Secret Scan)
# Rodzina: SECURITY | Klasa: FAST | Status: IMPLEMENTED
#
# Szybki skan sekretów w repo (git-tracked pliki). Deleguje do
# istniejącego tools/security/secret-scan.sh (gitleaks) gdy dostępny,
# w przeciwnym razie używa heurystyk (wzorce sekretów).
#
# Wykrywa:
#   * SECRET-FOUND        — znaleziono wzorzec sekretu w repo
#   * NO-SECRET-SCANNER   — brak narzędzia skanującego (gitleaks/trufflehog)
#   * NO-GITLEAKS-CONFIG  — brak .gitleaks.toml
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
p_say "=== P-016 SECRETS ==="
p_say "Szybki skan sekretów w repo (git-tracked pliki)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-016"

# ── EXECUTE ─────────────────────────────────────────────────
# Preferuj istniejący skaner (gitleaks/trufflehog/git-secrets).
SCANNER=""
if command -v gitleaks >/dev/null 2>&1; then
  SCANNER="gitleaks"
elif command -v trufflehog >/dev/null 2>&1; then
  SCANNER="trufflehog"
elif command -v git-secrets >/dev/null 2>&1; then
  SCANNER="git-secrets"
fi

SECRETS=0
if [ -n "$SCANNER" ]; then
  # Użyj istniejącego skanera (best-effort — nie blokuje na błędzie narzędzia).
  if bash tools/security/secret-scan.sh >/dev/null 2>&1; then
    SECRETS=0
  else
    SECRETS=1
  fi
else
  # Heurystyki: wzorce sekretów w git-tracked plikach (pomijamy .gitleaks.toml,
  # który zawiera WZORCE, nie realne sekrety).
  SECRETS=$(git ls-files -z 2>/dev/null | xargs -0 grep -lE \
    '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|password[[:space:]]*=[[:space:]]*[^[:space:]]+|api[_-]?key[[:space:]]*=[[:space:]]*[^[:space:]]+' \
    2>/dev/null | grep -v '\.gitleaks\.toml$' | wc -l)
fi

# Konfiguracja gitleaks.
GITLEAKS_CFG=0
if [ -f "$ROOT/.gitleaks.toml" ]; then
  GITLEAKS_CFG=1
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$SECRETS" -eq 0 ]; then
  p_pass "SECRETS-NONE-FOUND" BLOCKING "Brak wykrytych sekretów w repo (skaner: ${SCANNER:-heurystyki})"
else
  p_fail "SECRETS-FOUND" BLOCKING "Znaleziono $SECRETS plików z potencjalnymi sekretami"
fi
if [ -n "$SCANNER" ]; then
  p_pass "SECRETS-SCANNER-PRESENT" BLOCKING "Dostępny skaner sekretów: $SCANNER"
else
  p_warn "SECRETS-NO-SCANNER" "Brak gitleaks/trufflehog/git-secrets — użyto heurystyk"
fi
if [ "$GITLEAKS_CFG" -eq 1 ]; then
  p_pass "SECRETS-GITLEAKS-CONFIG" BLOCKING ".gitleaks.toml obecny"
else
  p_warn "SECRETS-NO-GITLEAKS-CONFIG" "Brak .gitleaks.toml w repo"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-016:secrets SECRETS=$SECRETS SCANNER=${SCANNER:-none} GITLEAKS_CFG=$GITLEAKS_CFG" "pipeline" "security/secrets.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$SECRETS" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-016" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-016" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "FAST" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
