#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# verify — AIGON Production Platform — Repository Certification Engine
# JEDNO WEJŚCIE, wiele wyspecjalizowanych świadków.
#
# Użycie:
#   ./tools/verify [SUBCOMMAND] [PROFILE]
#
# Subkomendy:
#   reconcile  — uruchamia wszystkie 4 warstwy (CANON/DRIFT/HISTORY/DEBT)
#   drift      — tylko warstwa CANON/DRIFT
#   history    — tylko warstwa HISTORY
#   debt       — tylko warstwa DEBT
#   (brak)     — domyślnie reconcile
#
# Profile (L0-L4):
#   L0 fast   — pre-commit, <5-10s
#   L1 full   — pre-push, pełna certyfikacja
#   L2 remote — CI
#   L3 release/genesis — pełna certyfikacja baseline
#   L4 history — reconciliation engine
#
# Zasada: "Jedno wejście, wiele wyspecjalizowanych świadków"
#   NIE jeden wielki skrypt — każdy moduł to osobny świadka.
# ─────────────────────────────────────────────────────────────
set -u

# ── Ścieżka do tools/verify ─────────────────────────────────
VERIFY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Wczytaj core ────────────────────────────────────────────
. "$VERIFY_DIR/core/lib.sh"
. "$VERIFY_DIR/core/profiles.sh"
. "$VERIFY_DIR/core/report.sh"
. "$VERIFY_DIR/core/reconcile.sh"

ROOT="$(verify_root)"
cd "$ROOT"

# ── Parsowanie argumentów ───────────────────────────────────
SUBCOMMAND="${1:-reconcile}"
PROFILE="${2:-full}"

# ── Nagłówek ────────────────────────────────────────────────
verify_header "$SUBCOMMAND/$PROFILE"

# ── Uruchomienie modułów ────────────────────────────────────
run_module() {
  local module="$1"
  local script="$VERIFY_DIR/$module"
  if [ -f "$script" ]; then
    say ""
    say "────────────────────────────────────────────────────────────"
    say "MODUŁ: $module"
    say "────────────────────────────────────────────────────────────"
    bash "$script"
  else
    warn "verify module $module" "Brak modułu: $script"
  fi
}

case "$SUBCOMMAND" in
  reconcile)
    # Wszystkie 4 warstwy + baseline diff
    run_module "reconcile/baseline.sh"
    run_module "reconcile/reconcile.sh"
    run_module "drift/drift.sh"
    run_module "history/history.sh"
    run_module "debt/scanner.sh"
    run_module "debt/debt.sh"
    ;;
  drift)
    run_module "drift/drift.sh"
    ;;
  history)
    run_module "history/history.sh"
    ;;
  debt)
    run_module "debt/scanner.sh"
    run_module "debt/debt.sh"
    ;;
  *)
    say "Nieznana subkomenda: $SUBCOMMAND"
    say "Dostępne: reconcile | drift | history | debt"
    exit 2
    ;;
esac

# ── Podsumowanie ────────────────────────────────────────────
say ""
verify_summary
