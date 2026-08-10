#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/security.sh — GATE-005 SECURITY
# Weryfikuje brak hardcoded sekretów w repo.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-005 SECURITY ==="

# ── SECURITY-001: brak hardcoded sekretów ───────────────────
# Wzorce: sk-... (API keys), AKIA... (AWS), BEGIN PRIVATE KEY,
# token=..., password=..., secret=...
# Uwaga: katalog tools/verify/ jest WYŁĄCZONY ze skanowania, bo zawiera
# wzorce detekcyjne (regex-y) w kodzie narzędzi weryfikacyjnych — to nie są
# rzeczywiste sekrety, a skanowanie ich powodowałoby fałszywe pozytywy.
SECRET_COUNT=0
SECRET_DETAIL=""
while IFS= read -r f; do
  case "$f" in
    *.md|*.txt|*.log) continue ;;
  esac
  if grep -qE 'sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|password[[:space:]]*[:=][[:space:]]*[^[:space:]]+|secret[[:space:]]*[:=][[:space:]]*[^[:space:]]+' "$f" 2>/dev/null; then
    SECRET_COUNT=$((SECRET_COUNT+1))
    SECRET_DETAIL="$SECRET_DETAIL $f"
  fi
done < <(find . -type f -not -path './.git/*' -not -path './node_modules/*' -not -path './.venv/*' -not -path './tools/verify/*' 2>/dev/null)

if [ "$SECRET_COUNT" -eq 0 ]; then
  pass "SECURITY-001 brak hardcoded sekretów" BLOCKING "Brak wykrytych sekretów w repo."
else
  fail "SECURITY-001 brak hardcoded sekretów" BLOCKING "$SECRET_COUNT plików z potencjalnymi sekretami:$SECRET_DETAIL"
fi

# ── SECURITY-002: .gitignore chroni sekrety ─────────────────
if [ -f "./.gitignore" ]; then
  if grep -qE '\.env|\.pem|\.key|secrets|credentials' ./.gitignore 2>/dev/null; then
    pass "SECURITY-002 .gitignore chroni sekrety" BLOCKING ".gitignore zawiera wzorce sekretów."
  else
    warn "SECURITY-002 .gitignore chroni sekrety" ".gitignore nie zawiera wzorców sekretów (.env, .pem, .key)."
  fi
else
  fail "SECURITY-002 .gitignore chroni sekrety" BLOCKING "Brak .gitignore."
fi

# ── SECURITY-003: brak plików .env w repo ───────────────────
ENV_COUNT=$(find . -name '.env' -not -path './.git/*' 2>/dev/null | wc -l)
if [ "$ENV_COUNT" -eq 0 ]; then
  pass "SECURITY-003 brak .env w repo" BLOCKING "Brak plików .env w repo."
else
  fail "SECURITY-003 brak .env w repo" BLOCKING "$ENV_COUNT plików .env w repo."
fi

verify_module_exit
