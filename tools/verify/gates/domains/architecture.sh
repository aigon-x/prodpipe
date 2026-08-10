#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/architecture.sh — GATE-007 ARCHITECTURE
# Weryfikuje że architektura jest zgodna z deklaracją.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-007 ARCHITECTURE ==="

# ── ARCHITECTURE-001: deklaracja architektury istnieje ──────
if [ -f "./ARCHITECTURE.md" ] || [ -f "./docs/ARCHITECTURE.md" ]; then
  pass "ARCHITECTURE-001 deklaracja architektury" BLOCKING "Plik ARCHITECTURE.md obecny."
else
  fail "ARCHITECTURE-001 deklaracja architektury" BLOCKING "Brak ARCHITECTURE.md."
fi

# ── ARCHITECTURE-002: brak orphaned modułów ─────────────────
# Moduły w tools/verify/* które nie są podłączone do verify.sh.
ORPHANED=0
ORPHANED_DETAIL=""
if [ -d "./tools/verify" ]; then
  while IFS= read -r mod; do
    base=$(basename "$mod")
    # Sprawdź czy moduł jest wywoływany w verify.sh
    if ! grep -q "$base" ./tools/verify/verify.sh 2>/dev/null; then
      ORPHANED=$((ORPHANED+1))
      ORPHANED_DETAIL="$ORPHANED_DETAIL $base"
    fi
  done < <(find ./tools/verify -maxdepth 2 -name '*.sh' -not -path '*/core/*' -not -path '*/gates/*' 2>/dev/null)
fi
if [ "$ORPHANED" -eq 0 ]; then
  pass "ARCHITECTURE-002 brak orphaned modułów" BLOCKING "Wszystkie moduły verify podłączone."
else
  warn "ARCHITECTURE-002 brak orphaned modułów" "$ORPHANED orphaned modułów:$ORPHANED_DETAIL"
fi

# ── ARCHITECTURE-003: brak shadow system ────────────────────
# Duplikacja logiki weryfikacji poza tools/verify.
SHADOW=0
if [ -f "./.git-hooks/validate-sot" ]; then
  SHADOW=$((SHADOW+1))
fi
if [ "$SHADOW" -eq 0 ]; then
  pass "ARCHITECTURE-003 brak shadow system" BLOCKING "Brak duplikacji logiki weryfikacji."
else
  warn "ARCHITECTURE-003 brak shadow system" "Znaleziono shadow system (.git-hooks/validate-sot)."
fi

verify_module_exit
