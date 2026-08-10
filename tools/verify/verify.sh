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

# ── Mapowanie nazwy modułu → ścieżka skryptu ────────────────
# Każdy moduł z profiles.sh (git, security, structure, ...) ma
# odpowiadający skrypt w tools/verify/<kategoria>/<nazwa>.sh.
# To jest JEDYNE miejsce mapowania — profiles.sh deklaruje moduły,
# verify.sh je uruchamia. Rozjazd (FALSE GATE) jest tu naprawiony.
module_script() {
  local module="$1"
  case "$module" in
    git)            echo "git/integrity.sh" ;;
    security)       echo "security/secrets.sh" ;;
    structure)      echo "structure/readme.sh" ;;
    architecture)   echo "architecture/architecture.sh" ;;
    dependencies)   echo "dependencies/dependencies.sh" ;;
    reproducibility) echo "reproducibility/reproducibility.sh" ;;
    deployment)     echo "deployment/deployment.sh" ;;
    contracts)      echo "contracts/contracts.sh" ;;
    migration)      echo "migration/migration.sh" ;;
    recovery)       echo "recovery/recovery.sh" ;;
    *)              echo "" ;;
  esac
}

# ── Uruchomienie modułu ─────────────────────────────────────
# run_module <module>   — moduł profilu (mapowany przez module_script)
# run_module <path.sh>  — bezpośrednia ścieżka (warstwy reconcile)
run_module() {
  local name="$1"
  local script
  # Argument z "/" to bezpośrednia ścieżka; w przeciwnym razie mapuj nazwę.
  case "$name" in
    */*) script="$VERIFY_DIR/$name" ;;
    *)   script="$VERIFY_DIR/$(module_script "$name")" ;;
  esac
  if [ -n "$script" ] && [ -f "$script" ]; then
    say ""
    say "────────────────────────────────────────────────────────────"
    say "MODUŁ: $name"
    say "────────────────────────────────────────────────────────────"
    bash "$script"
    local rc=$?
    # Agregacja: każdy FAIL w module (exit != 0) podnosi VERIFY_FAIL
    # w procesie głównym, więc verify_summary/verify_blocked to wykryje.
    if [ "$rc" -ne 0 ]; then
      VERIFY_FAIL=$((VERIFY_FAIL + 1))
      fail "verify module $name" BLOCKING "Moduł zakończył się kodem $rc (oczekiwano 0)."
    fi
  else
    warn "verify module $name" "Brak modułu: $script"
  fi
}

# ── Uruchomienie modułów dla profilu ────────────────────────
# verify_profile_modules() (z profiles.sh) zwraca listę modułów
# dla danego profilu. To eliminuje FALSE GATE — PROFILE jest
# respektowany, a nie parsowany i ignorowany.
run_profile_modules() {
  local profile="$1"
  local modules
  modules="$(verify_profile_modules "$profile")"
  local m
  for m in $modules; do
    run_module "$m"
  done
}

# ── Subkomendy ──────────────────────────────────────────────
# reconcile = wszystkie moduły profilu + warstwy reconcile.
# drift/history/debt = tylko odpowiednie warstwy.
case "$SUBCOMMAND" in
  reconcile)
    # Wszystkie moduły profilu (git, security, structure, ...)
    run_profile_modules "$PROFILE"
    # Warstwy reconcile (baseline + orchestrator)
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
  gates)
    # System gate'ów jakości (OPERATION GATEFORGE).
    # Uruchamia enforcement dla profilu (domyślnie LOCAL_FAST) + meta-gate.
    # PROFILE: LOCAL_FAST | PRE_PUSH | CI | RELEASE
    GATES_PROFILE="${PROFILE:-LOCAL_FAST}"
    say "=== GATES (profile: $GATES_PROFILE) ==="
    # Enforcement: uruchamia wszystkie gate'y przypisane do profilu.
    bash "$VERIFY_DIR/gates/enforcement.sh" "$GATES_PROFILE"
    gates_rc=$?
    if [ "$gates_rc" -ne 0 ]; then
      VERIFY_FAIL=$((VERIFY_FAIL + 1))
      fail "gates enforcement" BLOCKING "Enforcement zakończył się kodem $gates_rc."
    fi
    # Meta-gate: weryfikuje spójność całego systemu gate'ów.
    bash "$VERIFY_DIR/gates/gate-integrity.sh"
    integrity_rc=$?
    if [ "$integrity_rc" -ne 0 ]; then
      VERIFY_FAIL=$((VERIFY_FAIL + 1))
      fail "gates gate-integrity" BLOCKING "Meta-gate zakończył się kodem $integrity_rc."
    fi
    ;;
  *)
    say "Nieznana subkomenda: $SUBCOMMAND"
    say "Dostępne: reconcile | drift | history | debt | gates"
    exit 2
    ;;
esac

# ── Podsumowanie ────────────────────────────────────────────
# verify_module_exit wypisuje podsumowanie i propaguje status
# (exit 0 = PASS, exit 1 = FAIL) do procesu nadrzędnego.
verify_module_exit
