#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/canonicality.sh — GATE-003 CANONICALITY
# Weryfikuje że config/canonical jest jedynym źródłem prawdy.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-003 CANONICALITY ==="

# ── CANONICALITY-001: katalog canonical istnieje ────────────
if [ -d "./config/canonical" ]; then
  pass "CANONICALITY-001 config/canonical istnieje" BLOCKING "Katalog config/canonical obecny."
else
  fail "CANONICALITY-001 config/canonical istnieje" BLOCKING "Brak config/canonical."
fi

# ── CANONICALITY-002: brak duplikacji konfiguracji ──────────
# Szukamy plików konfiguracyjnych poza config/canonical, które
# deklarują ten sam kanon (shadow config).
SHADOW_CONFIG=0
if [ -d "./config" ]; then
  # Pliki yaml/json w config/ poza canonical
  while IFS= read -r f; do
    case "$f" in
      ./config/canonical/*) continue ;;
      *) SHADOW_CONFIG=$((SHADOW_CONFIG+1)) ;;
    esac
  done < <(find ./config -type f \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) 2>/dev/null)
fi
if [ "$SHADOW_CONFIG" -eq 0 ]; then
  pass "CANONICALITY-002 brak shadow config" BLOCKING "Brak duplikacji konfiguracji poza config/canonical."
else
  warn "CANONICALITY-002 brak shadow config" "$SHADOW_CONFIG plików konfiguracyjnych poza config/canonical."
fi

# ── CANONICALITY-003: canonical nie jest pusty ──────────────
if [ -d "./config/canonical" ]; then
  count=$(find ./config/canonical -type f 2>/dev/null | wc -l)
  if [ "$count" -gt 0 ]; then
    pass "CANONICALITY-003 canonical niepusty" BLOCKING "$count plików w config/canonical."
  else
    fail "CANONICALITY-003 canonical niepusty" BLOCKING "config/canonical jest pusty."
  fi
fi

verify_module_exit
