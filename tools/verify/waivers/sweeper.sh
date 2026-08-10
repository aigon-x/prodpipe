#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# waivers/sweeper.sh — AIGON Production Platform — Waiver Sweeper
# Moduł: WAIVER SWEEPER (warstwa governance/audyt)
# Czyści wygasłe wyjątki (waivers) z tabeli `waivers` w StateStore.
#
# Zasada konstytucyjna: "wyjątki wygasają".
#   - waiver BEZ expires_at (NULL lub pusty) jest NIELEGALNY → FAIL (BLOCKING)
#   - wygasły waiver (expires_at < now) MUSI zostać usunięty
#   - aktywny waiver (expires_at >= now) zostaje
#
# Checki:
#   WAIVER-101  Wygasłe waivery usunięte (sweep)
#   WAIVER-102  Waiver bez expires_at — NIELEGALNY (konstytucja)
#   WAIVER-103  Tabela waivers istnieje (migracja 0003 uruchomiona)
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== WAIVER SWEEPER (WAIVERS) ==="

# ── Ścieżka do bazy StateStore ──────────────────────────────
# Respektuj VERIFY_STATE_DB override (testy), inaczej canonical-state.db.
DB="${VERIFY_STATE_DB:-}"
if [ -z "$DB" ]; then
  DB="$ROOT/system/control-plane/state/data/canonical-state.db"
fi

# ── WAIVER-103 Tabela waivers istnieje ──────────────────────
say ""
say "--- WAIVERS: tabela ---"
if ! command -v sqlite3 >/dev/null 2>&1; then
  fail "WAIVER-103 Tabela waivers" BLOCKING "sqlite3 niedostępny — nie można czyścić waiverów."
  verify_module_exit
fi
if [ ! -f "$DB" ]; then
  info "WAIVER-103 Tabela waivers" "Brak bazy StateStore: $DB — migracja 0003 nie uruchomiona. To nie jest błąd."
  verify_module_exit
fi
if ! sqlite3 "$DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='waivers';" 2>/dev/null | grep -q waivers; then
  info "WAIVER-103 Tabela waivers" "Tabela waivers nie istnieje — migracja 0003 nie uruchomiona. To nie jest błąd."
  verify_module_exit
fi
pass "WAIVER-103 Tabela waivers" BLOCKING "Tabela waivers istnieje (migracja 0003 uruchomiona)."

# ── WAIVER-102 Waivery bez expires_at — NIELEGALNE ──────────
say ""
say "--- WAIVERS: wyjątki bez wygaśnięcia (NIELEGALNE) ---"
# Zasada: wyjątki wygasają. Waiver bez expires_at (NULL lub pusty) łamie konstytucję.
ILLEGAL=0
while IFS='|' read -r id check_id scope expires_at; do
  [ -z "$id" ] && continue
  ILLEGAL=$((ILLEGAL+1))
  fail "WAIVER-102 Waiver bez expires_at" BLOCKING "id=$id check_id=$check_id scope=$scope expires_at='$expires_at' — NIELEGALNY (wyjątki wygasają)."
done < <(sqlite3 -separator '|' "$DB" "SELECT id, check_id, scope, expires_at FROM waivers WHERE expires_at IS NULL OR expires_at = '';" 2>/dev/null)

if [ "$ILLEGAL" -eq 0 ]; then
  pass "WAIVER-102 Waiver bez expires_at" BLOCKING "Brak waiverów bez expires_at — wszystkie wyjątki mają wygaśnięcie."
fi

# ── WAIVER-101 Wygasłe waivery — sweep ──────────────────────
say ""
say "--- WAIVERS: sweep wygasłych ---"
# Wygasły waiver (expires_at < now) MUSI zostać usunięty.
SWEPT=0
while IFS='|' read -r id check_id scope expires_at; do
  [ -z "$id" ] && continue
  SWEPT=$((SWEPT+1))
  say "  Sweep: id=$id check_id=$check_id scope=$scope expires_at=$expires_at"
  if sqlite3 "$DB" "DELETE FROM waivers WHERE id = $id;" 2>/dev/null; then
    evidence_record "verify:waivers:swept:$check_id" "module" "waivers/sweeper.sh"
  else
    fail "WAIVER-101 Sweep wygasłego waivers" BLOCKING "id=$id — DELETE NIE powiódł się."
  fi
done < <(sqlite3 -separator '|' "$DB" "SELECT id, check_id, scope, expires_at FROM waivers WHERE expires_at < datetime('now');" 2>/dev/null)

# ── Podsumowanie ────────────────────────────────────────────
ACTIVE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM waivers WHERE expires_at >= datetime('now');" 2>/dev/null)
ACTIVE=${ACTIVE:-0}
say ""
say "--- WAIVERS: podsumowanie ---"
say "  Wygasłe usunięte: $SWEPT"
say "  Aktywne pozostały: $ACTIVE"
if [ "$SWEPT" -gt 0 ]; then
  info "WAIVER-101 Sweep wygasłych waiverów" "$SWEPT wygasłych waiverów usunięto, $ACTIVE aktywnych zostało."
else
  pass "WAIVER-101 Sweep wygasłych waiverów" BLOCKING "Brak wygasłych waiverów — $ACTIVE aktywnych."
fi

# ── Evidence + zakończenie ──────────────────────────────────
evidence_record "verify:waivers:sweeper:complete" "module" "waivers/sweeper.sh"
verify_module_exit
