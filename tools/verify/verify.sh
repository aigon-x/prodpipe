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
    local rc=$?
    # Agregacja: każdy FAIL w module (exit != 0) podnosi VERIFY_FAIL
    # w procesie głównym, więc verify_summary/verify_blocked to wykryje.
    if [ "$rc" -ne 0 ]; then
      VERIFY_FAIL=$((VERIFY_FAIL + 1))
      fail "verify module $module" BLOCKING "Moduł zakończył się kodem $rc (oczekiwano 0)."
    fi
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
  config)
    # CONFIG ZERO — walidacja konfiguracji kanonicznej przez kompilator
    say ""
    say "────────────────────────────────────────────────────────────"
    say "MODUŁ: config (config-compiler validate)"
    say "────────────────────────────────────────────────────────────"
    if [ -f "$ROOT/tools/config/config-compiler.sh" ]; then
      bash "$ROOT/tools/config/config-compiler.sh" validate
      rc=$?
      if [ "$rc" -ne 0 ]; then
        VERIFY_FAIL=$((VERIFY_FAIL + 1))
        fail "config compiler validate" BLOCKING "Kompilator zwrócił kod $rc (oczekiwano 0)."
      else
        pass "config compiler validate" BLOCKING "Konfiguracja kanoniczna jest poprawna."
      fi
    else
      warn "config compiler" "Brak kompilatora: $ROOT/tools/config/config-compiler.sh"
    fi
    ;;
  *)
    say "Nieznana subkomenda: $SUBCOMMAND"
    say "Dostępne: reconcile | drift | history | debt | config"
    exit 2
    ;;
esac

# ── Podsumowanie ────────────────────────────────────────────
say ""
verify_summary
exit $?
