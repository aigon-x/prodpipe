#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# security/credentials.sh — AIGON Production Platform — Repository Certification Engine
# Moduł: SECURITY — CREDENTIALS
# Wykrywa credentials w plikach (poza sekretami objętymi gitleaks).
#
# Checki:
#   SEC-201  No AWS credentials
#   SEC-202  No GCP credentials
#   SEC-203  No Azure credentials
#   SEC-204  No database URLs with credentials
#   SEC-205  No LLM provider keys
#   SEC-206  No Docker registry credentials
#   SEC-207  No Tailscale/auth keys
#   SEC-208  No JWT tokens
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== SECURITY — CREDENTIALS ==="

# Wykluczamy katalogi, które mogą zawierać wzorce jako stringi (testy, docs).
EXCLUDE="--exclude-dir=.git --exclude-dir=.git-hooks --exclude-dir=.github --exclude-dir=archive"

# SEC-201 No AWS credentials
if grep -rInE 'AKIA[0-9A-Z]{16}' $EXCLUDE . 2>/dev/null | grep -q .; then
  fail "SEC-201 No AWS credentials" BLOCKING "Znaleziono AWS access key."
else
  pass "SEC-201 No AWS credentials"
fi

# SEC-202 No GCP credentials
if grep -rInE 'AIza[0-9A-Za-z_-]{35}' $EXCLUDE . 2>/dev/null | grep -q .; then
  fail "SEC-202 No GCP credentials" BLOCKING "Znaleziono GCP API key."
else
  pass "SEC-202 No GCP credentials"
fi

# SEC-203 No Azure credentials
if grep -rInE 'AccountKey=[A-Za-z0-9+/=]{40,}' $EXCLUDE . 2>/dev/null | grep -q .; then
  fail "SEC-203 No Azure credentials" BLOCKING "Znaleziono Azure storage key."
else
  pass "SEC-203 No Azure credentials"
fi

# SEC-204 No database URLs with credentials
if grep -rInE '(postgres|mysql|mongodb|redis)://[^:]+:[^@]+@' $EXCLUDE . 2>/dev/null | grep -q .; then
  fail "SEC-204 No database URLs with credentials" BLOCKING "Znaleziono DB URL z credentials."
else
  pass "SEC-204 No database URLs with credentials"
fi

# SEC-205 No LLM provider keys
# OpenAI sk-, Anthropic sk-ant-, DeepSeek sk-, Google AIza
if grep -rInE '(sk-[A-Za-z0-9]{20,}|sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{32,})' $EXCLUDE . 2>/dev/null | grep -q .; then
  fail "SEC-205 No LLM provider keys" BLOCKING "Znaleziono LLM provider key."
else
  pass "SEC-205 No LLM provider keys"
fi

# SEC-206 No Docker registry credentials
if grep -rInE '(docker|registry)://[^:]+:[^@]+@' $EXCLUDE . 2>/dev/null | grep -q .; then
  fail "SEC-206 No Docker registry credentials" BLOCKING "Znaleziono Docker registry credentials."
else
  pass "SEC-206 No Docker registry credentials"
fi

# SEC-207 No Tailscale/auth keys
if grep -rInE 'tskey-[A-Za-z0-9_-]{20,}' $EXCLUDE . 2>/dev/null | grep -q .; then
  fail "SEC-207 No Tailscale/auth keys" BLOCKING "Znaleziono Tailscale auth key."
else
  pass "SEC-207 No Tailscale/auth keys"
fi

# SEC-208 No JWT tokens
if grep -rInE 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' $EXCLUDE . 2>/dev/null | grep -q .; then
  fail "SEC-208 No JWT tokens" BLOCKING "Znaleziono JWT token."
else
  pass "SEC-208 No JWT tokens"
fi

say ""
