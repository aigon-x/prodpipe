#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# security/history.sh — AIGON Production Platform — Repository Certification Engine
# Moduł: SECURITY — SECRETS IN HISTORY
# Skanuje całą historię git pod kątem sekretów.
# "usunąłem sekret w następnym commicie" ≠ sekret nie istnieje.
#
# Checki:
#   SEC-101  No secrets in entire history (gitleaks)
#   SEC-102  No secrets in recent commits (informational)
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== SECURITY — SECRETS IN HISTORY ==="

# SEC-101 No secrets in entire history (gitleaks)
if command -v gitleaks >/dev/null 2>&1; then
  if gitleaks detect --source "$ROOT" --no-banner --log-opts="--all" >/dev/null 2>&1; then
    pass "SEC-101 No secrets in entire history" "gitleaks — brak sekretów w całej historii."
  else
    fail "SEC-101 No secrets in entire history" BLOCKING "gitleaks wykrył sekrety w historii."
  fi
else
  info "SEC-101 No secrets in entire history" "gitleaks niedostępny — pominięto."
fi

# SEC-102 No secrets in recent commits (informational)
# Szybki scan ostatnich 10 commitów.
if command -v gitleaks >/dev/null 2>&1; then
  if gitleaks detect --source "$ROOT" --no-banner --log-opts="-10" >/dev/null 2>&1; then
    pass "SEC-102 No secrets in recent commits" "gitleaks — brak sekretów w ostatnich 10 commitach."
  else
    info "SEC-102 No secrets in recent commits" "gitleaks wykrył sekrety w ostatnich commitach."
  fi
else
  info "SEC-102 No secrets in recent commits" "gitleaks niedostępny — pominięto."
fi

verify_module_exit
