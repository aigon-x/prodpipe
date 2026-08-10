#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# security/sec-secrets-scan.sh — AIGON Production Platform — Repository Certification Engine
# Moduł: SEC-BASELINE — SECRETS SCAN (SEC-D-07) + GIT HISTORY SCAN (SEC-R-10)
# Wykrywa sekrety w working tree (SEC-D-07) i w całej historii git (SEC-R-10).
#
# SEC-BASELINE: ten moduł rodzi się w KAŻDYM projekcie utworzonym z template'u.
# ZASADA TEMPLATE: skrypt MUSI przechodzić na świeżym projekcie (jeszcze bez
# kodu domenowego). Placeholdery sekretów w template NIE są realnymi sekretami.
# Self-scan na samym template musi dawać PASS.
#
# Checki:
#   SEC-D-07  No secrets in working tree (gitleaks + .gitleaks.toml)
#   SEC-R-10  No secrets in entire git history (gitleaks --log-opts="--all")
#
# Delegacja: preferuje gitleaks z .gitleaks.toml (jeśli dostępny). Fallback
# do heurystyk (grep) — spójny z tools/security/secret-scan.sh. Brak gitleaks
# NIE jest automatycznym PASS — heurystyki muszą przejść (fail-closed).
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== SEC-BASELINE — SECRETS SCAN (SEC-D-07) + GIT HISTORY (SEC-R-10) ==="

GITLEAKS_CONFIG="$ROOT/.gitleaks.toml"
GITLEAKS_OK=0
if command -v gitleaks >/dev/null 2>&1; then
  GITLEAKS_OK=1
fi

# ── SEC-D-07 No secrets in working tree ─────────────────────
# Skanuje working tree (git-tracked pliki) pod kątem sekretów.
# Preferuje gitleaks z .gitleaks.toml; fallback do heurystyk.
if [ "$GITLEAKS_OK" -eq 1 ]; then
  if [ -f "$GITLEAKS_CONFIG" ]; then
    if gitleaks detect --source "$ROOT" --config "$GITLEAKS_CONFIG" --no-banner >/dev/null 2>&1; then
      pass "SEC-D-07 No secrets in working tree" BLOCKING "gitleaks (.gitleaks.toml) — brak sekretów w working tree."
    else
      fail "SEC-D-07 No secrets in working tree" BLOCKING "gitleaks wykrył sekrety w working tree (SEC-D-07)."
    fi
  else
    if gitleaks detect --source "$ROOT" --no-banner >/dev/null 2>&1; then
      pass "SEC-D-07 No secrets in working tree" BLOCKING "gitleaks (default config) — brak sekretów w working tree."
    else
      fail "SEC-D-07 No secrets in working tree" BLOCKING "gitleaks wykrył sekrety w working tree (SEC-D-07)."
    fi
  fi
else
  # Fallback heurystyczny — spójny z tools/security/secret-scan.sh.
  # Skanujemy tylko git-tracked pliki (repo_files), nie nieśledzone artefakty.
  HEUR_FAIL=0
  # API keys / tokens / secrets assignments.
  if repo_files | grep -vE '\.(md|sh)$' | xargs -r grep -InE '(api[_-]?key|secret|password|passwd|token|auth[_-]?token|access[_-]?key|private[_-]?key)\s*[:=]\s*["'"'"'][A-Za-z0-9_\-]{16,}["'"'"']' 2>/dev/null | grep -q .; then
    HEUR_FAIL=1
  fi
  # Private keys.
  if repo_files | xargs -r grep -IlE 'BEGIN (RSA|OPENSSH|EC|DSA|PGP) PRIVATE KEY' 2>/dev/null | grep -q .; then
    HEUR_FAIL=1
  fi
  # Cloud credentials (AWS).
  if repo_files | xargs -r grep -InE 'AKIA[0-9A-Z]{16}' 2>/dev/null | grep -q .; then
    HEUR_FAIL=1
  fi
  # JWT.
  if repo_files | xargs -r grep -InE 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' 2>/dev/null | grep -q .; then
    HEUR_FAIL=1
  fi
  if [ "$HEUR_FAIL" -eq 0 ]; then
    pass "SEC-D-07 No secrets in working tree" BLOCKING "gitleaks niedostępny — heurystyki: brak sekretów w working tree."
  else
    fail "SEC-D-07 No secrets in working tree" BLOCKING "gitleaks niedostępny — heurystyki wykryły sekrety w working tree (SEC-D-07)."
  fi
fi

# ── SEC-R-10 No secrets in entire git history ───────────────
# "usunąłem sekret w następnym commicie" ≠ sekret nie istnieje.
# Skanuje CAŁĄ historię git (--log-opts="--all").
if [ "$GITLEAKS_OK" -eq 1 ]; then
  if [ -f "$GITLEAKS_CONFIG" ]; then
    if gitleaks detect --source "$ROOT" --config "$GITLEAKS_CONFIG" --no-banner --log-opts="--all" >/dev/null 2>&1; then
      pass "SEC-R-10 No secrets in git history" BLOCKING "gitleaks (.gitleaks.toml) — brak sekretów w całej historii git."
    else
      fail "SEC-R-10 No secrets in git history" BLOCKING "gitleaks wykrył sekrety w historii git (SEC-R-10)."
    fi
  else
    if gitleaks detect --source "$ROOT" --no-banner --log-opts="--all" >/dev/null 2>&1; then
      pass "SEC-R-10 No secrets in git history" BLOCKING "gitleaks (default config) — brak sekretów w całej historii git."
    else
      fail "SEC-R-10 No secrets in git history" BLOCKING "gitleaks wykrył sekrety w historii git (SEC-R-10)."
    fi
  fi
else
  # Fallback: skan ostatnich commitów (git log -p) — ograniczony, ale lepszy
  # niż nic. Pełny skan historii wymaga gitleaks (fail-closed: brak gitleaks
  # + brak możliwości pełnego skanu = WARN, nie PASS).
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    HIST_FAIL=0
    if git log -p --all 2>/dev/null | grep -E '(api[_-]?key|secret|password|token)\s*[:=]\s*["'"'"'][A-Za-z0-9_\-]{16,}["'"'"']' | grep -q .; then
      HIST_FAIL=1
    fi
    if [ "$HIST_FAIL" -eq 0 ]; then
      warn "SEC-R-10 No secrets in git history" "gitleaks niedostępny — heurystyka na git log -p: brak sekretów w historii (pełny skan wymaga gitleaks)."
    else
      fail "SEC-R-10 No secrets in git history" BLOCKING "gitleaks niedostępny — heurystyka wykryła sekrety w historii git (SEC-R-10)."
    fi
  else
    info "SEC-R-10 No secrets in git history" "Brak commitów (HEAD nie istnieje) — brak historii do skanu."
  fi
fi

# ── Evidence ─────────────────────────────────────────────────
if verify_blocked; then
  evidence_record "verify:sec-secrets-scan:FAIL" "verify" "security/sec-secrets-scan.sh"
else
  evidence_record "verify:sec-secrets-scan:PASS" "verify" "security/sec-secrets-scan.sh"
fi

verify_module_exit
