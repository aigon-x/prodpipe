#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# verify — AIGON Production Platform — Repository Certification Engine
# JEDNO WEJŚCIE, wiele wyspecjalizowanych świadków.
#
# Użycie:
#   ./tools/verify [SUBCOMMAND] [PROFILE]
#
# Subkomendy:
#   reconcile  — uruchamia wszystkie 4 warstwy (CANON/DRIFT/HISTORY/DEBT) + waivers
#   drift      — tylko warstwa CANON/DRIFT
#   history    — tylko warstwa HISTORY
#   debt       — tylko warstwa DEBT
#   waivers    — tylko Waiver Sweeper (czyszczenie wygasłych wyjątków)
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

# ── Uruchomienie modułu ─────────────────────────────────────
# run_module <module>   — moduł profilu (mapowany przez module_script)
# run_module <path.sh>  — bezpośrednia ścieżka (warstwy reconcile)
# Każde uruchomienie to GATE: po zakończeniu zapisuje evidence do
# StateStore (P0#1). Moduł bez evidence = 0 punktów (metryka pokrycia).
VERIFY_RUN_COUNT=0

run_module() {
  local name="$1"
  local script
  # Argument z "/" lub kończący się na ".sh" to bezpośrednia ścieżka
  # (np. "reconcile/baseline.sh", "self-profile-integrity.sh"); w przeciwnym
  # razie mapuj nazwę modułu przez module_script (np. "git" → "git/integrity.sh").
  case "$name" in
    */*|*.sh) script="$VERIFY_DIR/$name" ;;
    *)        script="$VERIFY_DIR/$(module_script "$name")" ;;
  esac
  VERIFY_RUN_COUNT=$((VERIFY_RUN_COUNT+1))
  if [ -n "$script" ] && [ -f "$script" ]; then
    say ""
    say "────────────────────────────────────────────────────────────"
    say "MODUŁ: $name"
    say "────────────────────────────────────────────────────────────"
    bash "$script"
    local rc=$?
    # Agregacja: każdy FAIL w module (exit != 0) rejestrujemy jako FAIL
    # w procesie głównym. `fail` inkrementuje VERIFY_FAIL i VERIFY_CHECKS,
    # więc NIE inkrementujemy VERIFY_FAIL ręcznie (to był podwójny licznik).
    if [ "$rc" -ne 0 ]; then
      fail "verify module $name" BLOCKING "Moduł zakończył się kodem $rc (oczekiwano 0)."
    fi
    # Evidence bridge (P0#1): każdy uruchomiony gate zapisuje wynik.
    evidence_record "verify:$name:rc=$rc" "verify" "$script"
  else
    # FAIL-CLOSED (anti-drift): moduł zadeklarowany w profilu, a nieistniejący
    # = FAIL (BLOCKING), NIGDY skip. Wcześniej był to `warn` (FALSE GATE) —
    # ghost moduły (architecture, dependencies, ...) przechodziły cicho,
    # a drift wracał po 3 miesiącach. Teraz brak modułu blokuje certyfikację.
    fail "verify module $name" BLOCKING "Brak modułu: $script (fail-closed — moduł zadeklarowany, a nieistniejący)"
    # Ghost moduł też rejestruje evidence (FAIL), aby meta-gate wiedział,
    # że moduł był uruchomiony i zakończył się porażką.
    evidence_record "verify:$name:MODULE-MISSING" "verify" "$script"
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
#
# SELF-001 (self-profile-integrity.sh) jest META-GATE uruchamianym
# ZAWSZE, przed każdą subkomendą: weryfikuje, że każdy moduł
# zadeklarowany w profilach istnieje i jest wykonywalny. Ghost moduł
# = FAIL (BLOCKING), nigdy skip. Chroni przed FALSE GATE na zawsze.
run_module "self-profile-integrity.sh"

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
    run_module "waivers/sweeper.sh"
    # Moduły git/security/structure (R6: połączone z reconcile)
    run_module "git/integrity.sh"
    run_module "git/branches.sh"
    run_module "git/history.sh"
    run_module "git/tags.sh"
    run_module "security/secrets.sh"
    run_module "security/credentials.sh"
    run_module "security/history.sh"
    run_module "structure/readme.sh"
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
  waivers)
    run_module "waivers/sweeper.sh"
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
    say "Dostępne: reconcile | drift | history | debt | waivers | gates | config"
    exit 2
    ;;
esac

# ── Podsumowanie ────────────────────────────────────────────
# Meta-gate VERIFY-EVIDENCE-COMPLETE (P0#1): każdy uruchomiony moduł
# MUSI zapisać evidence do StateStore. Moduł bez evidence = 0 punktów.
# Uruchamiamy go PRZED verify_module_exit, aby jego wynik (PASS/FAIL)
# wszedł do agregacji i mógł zablokować certyfikację.
verify_evidence_complete "$VERIFY_RUN_COUNT"

# verify_module_exit wypisuje podsumowanie i propaguje status
# (exit 0 = PASS, exit 1 = FAIL) do procesu nadrzędnego.
verify_module_exit
