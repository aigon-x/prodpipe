#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/migration.sh — GATE-012 MIGRATION
# Weryfikuje że migracje StateStore są spójne.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-012 MIGRATION ==="

MIGRATIONS_DIR="./system/control-plane/state/migrations"

# ── MIGRATION-001: katalog migracji istnieje ────────────────
if [ -d "$MIGRATIONS_DIR" ]; then
  pass "MIGRATION-001 katalog migracji" BLOCKING "Katalog migracji obecny."
else
  fail "MIGRATION-001 katalog migracji" BLOCKING "Brak katalogu migracji."
fi

# ── MIGRATION-002: migracje są sekwencyjne ──────────────────
# Pliki 0001_*.sql, 0002_*.sql, ... — kolejność musi być ciągła.
if [ -d "$MIGRATIONS_DIR" ]; then
  SEQUENCE_OK=1
  prev=0
  while IFS= read -r f; do
    num=$(basename "$f" | cut -d_ -f1)
    # Wiodące zera (0008) są konwencją nazewniczą — wymuś podstawę 10.
    num10=$((10#$num))
    if [ "$num10" -ne $((prev+1)) ]; then
      SEQUENCE_OK=0
      break
    fi
    prev="$num10"
  done < <(find "$MIGRATIONS_DIR" -name '*.sql' 2>/dev/null | sort)
  if [ "$SEQUENCE_OK" -eq 1 ]; then
    pass "MIGRATION-002 migracje sekwencyjne" BLOCKING "Migracje w ciągłej sekwencji (ostatnia: $prev)."
  else
    fail "MIGRATION-002 migracje sekwencyjne" BLOCKING "Przerwa w sekwencji migracji."
  fi
fi

# ── MIGRATION-003: schema_version spójna ────────────────────
# STATE_SCHEMA_VERSION w lib.sh powinna odpowiadać ostatniej migracji.
if [ -f "./system/control-plane/state/lib.sh" ]; then
  declared=$(grep -E 'STATE_SCHEMA_VERSION=' ./system/control-plane/state/lib.sh | head -1 | sed 's/.*="\([0-9]*\)".*/\1/')
  if [ -d "$MIGRATIONS_DIR" ]; then
    last_migration=$(find "$MIGRATIONS_DIR" -name '*.sql' 2>/dev/null | sort | tail -1 | xargs -r basename | cut -d_ -f1)
    # Porównanie liczbowe: "2" == "0002" (wiodące zera w nazwie pliku migracji
    # są konwencją nazewniczą, nie wartością — STATE_SCHEMA_VERSION="2").
    declared_num=$((10#$declared))
    last_num=$((10#$last_migration))
    if [ -n "$declared" ] && [ "$declared_num" -eq "$last_num" ]; then
      pass "MIGRATION-003 schema_version spójna" BLOCKING "STATE_SCHEMA_VERSION=$declared == ostatnia migracja $last_migration."
    else
      fail "MIGRATION-003 schema_version spójna" BLOCKING "STATE_SCHEMA_VERSION=$declared != ostatnia migracja $last_migration."
    fi
  fi
fi

verify_module_exit
