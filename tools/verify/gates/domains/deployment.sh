#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/deployment.sh — GATE-010 DEPLOYMENT
# Weryfikuje że deploy jest zgodny z kontraktem.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-010 DEPLOYMENT ==="

# ── DEPLOYMENT-001: skrypt deploy istnieje ──────────────────
if [ -f "./deploy.sh" ] || [ -f "./scripts/deploy.sh" ]; then
  pass "DEPLOYMENT-001 skrypt deploy" BLOCKING "Skrypt deploy obecny."
else
  info "DEPLOYMENT-001 skrypt deploy" "Brak skryptu deploy (repo bez deploy)."
fi

# ── DEPLOYMENT-002: brak hardcoded środowisk w deploy ───────
# Deploy nie powinien mieć hardcoded adresów produkcyjnych.
HARDCODED_ENV=0
for f in ./deploy.sh ./scripts/deploy.sh; do
  [ -f "$f" ] || continue
  if grep -qE 'production|prod[0-9]|\.aigon\.pl' "$f" 2>/dev/null; then
    HARDCODED_ENV=$((HARDCODED_ENV+1))
  fi
done
if [ "$HARDCODED_ENV" -eq 0 ]; then
  pass "DEPLOYMENT-002 brak hardcoded środowisk" BLOCKING "Brak hardcoded środowisk w deploy."
else
  warn "DEPLOYMENT-002 brak hardcoded środowisk" "$HARDCODED_ENV plików deploy z hardcoded środowiskami."
fi

# ── DEPLOYMENT-003: deploy.sh ma set -euo pipefail ──────────
if [ -f "./deploy.sh" ]; then
  if grep -q 'set -euo pipefail' ./deploy.sh 2>/dev/null; then
    pass "DEPLOYMENT-003 deploy.sh set -euo pipefail" BLOCKING "deploy.sh ma set -euo pipefail."
  else
    fail "DEPLOYMENT-003 deploy.sh set -euo pipefail" BLOCKING "deploy.sh nie ma set -euo pipefail."
  fi
fi

verify_module_exit
