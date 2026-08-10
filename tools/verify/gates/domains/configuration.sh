#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/configuration.sh — GATE-004 CONFIGURATION
# Weryfikuje że każdy element ma źródło konfiguracji.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-004 CONFIGURATION ==="

# ── CONFIGURATION-001: katalog config istnieje ──────────────
if [ -d "./config" ]; then
  pass "CONFIGURATION-001 config istnieje" BLOCKING "Katalog config obecny."
else
  fail "CONFIGURATION-001 config istnieje" BLOCKING "Brak katalogu config."
fi

# ── CONFIGURATION-002: brak hardcoded konfiguracji w kodzie ─
# Szukamy wzorców hardcoded (adresy IP, porty, ścieżki) w kodzie
# które powinny być w config. To jest WARNING (nie zawsze hardcode).
HARDCODED=0
HARDCODED_DETAIL=""
while IFS= read -r f; do
  case "$f" in
    *.sh|*.py|*.rs|*.go|*.ts|*.js) ;;
    *) continue ;;
  esac
  if grep -qE 'localhost:[0-9]{4,5}|127\.0\.0\.1:[0-9]{4,5}' "$f" 2>/dev/null; then
    HARDCODED=$((HARDCODED+1))
    HARDCODED_DETAIL="$HARDCODED_DETAIL $f"
  fi
done < <(find . -type f -not -path './.git/*' -not -path './tools/verify/*' -not -path './node_modules/*' 2>/dev/null)

if [ "$HARDCODED" -eq 0 ]; then
  pass "CONFIGURATION-002 brak hardcoded" BLOCKING "Brak hardcoded adresów/portów w kodzie."
else
  warn "CONFIGURATION-002 brak hardcoded" "$HARDCODED plików z hardcoded adresami:$HARDCODED_DETAIL"
fi

# ── CONFIGURATION-003: config nie jest pusty ────────────────
if [ -d "./config" ]; then
  count=$(find ./config -type f 2>/dev/null | wc -l)
  if [ "$count" -gt 0 ]; then
    pass "CONFIGURATION-003 config niepusty" BLOCKING "$count plików w config."
  else
    fail "CONFIGURATION-003 config niepusty" BLOCKING "config jest pusty."
  fi
fi

verify_module_exit
