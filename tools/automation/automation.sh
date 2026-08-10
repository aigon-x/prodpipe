#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# automation — AIGON Production Platform — Pipeline Operating System
# JEDNO WEJŚCIE, wiele wyspecjalizowanych pipeline'ów.
#
# Użycie:
#   ./tools/automation [SUBCOMMAND] [CLASS]
#
# Subkomendy:
#   verify   — uruchamia pipeline'y klasy FAST/STANDARD (pre-commit/pre-push)
#   audit    — uruchamia pipeline'y klasy DEEP (CI, niezależna weryfikacja)
#   release  — uruchamia pipeline'y klasy RELEASE (pełna certyfikacja baseline)
#   deploy   — uruchamia pipeline'y klasy RELEASE + DEPLOYMENT (wdrożenie)
#   certify  — uruchamia pipeline'y klasy CONTINUOUS (ciągła certyfikacja)
#   list     — wypisuje katalog pipeline'ów (P-001..P-051)
#   (brak)   — domyślnie verify
#
# Klasy wykonania (L0-L4):
#   FAST       — <10s, pre-commit, oczywiste błędy
#   STANDARD   — <1-3min, pre-push, pełna certyfikacja lokalna
#   DEEP       — minuty, CI, niezależna weryfikacja
#   RELEASE    — pełna certyfikacja baseline/release
#   CONTINUOUS — ciągłe monitorowanie / asynchroniczne
#
# Zasada: "Jedno wejście, wiele wyspecjalizowanych pipeline'ów"
#   NIE jeden wielki skrypt — każdy pipeline to osobny świadka.
#   Każdy pipeline realizuje wspólny Pipeline Contract (8 faz) i raportuje
#   DUAL VERDICT (IMPLEMENTATION vs REPOSITORY).
# ─────────────────────────────────────────────────────────────
set -u

# ── Ścieżka do tools/automation ─────────────────────────────
AUTOMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Wczytaj core ────────────────────────────────────────────
. "$AUTOMATION_DIR/core/lib.sh"
. "$AUTOMATION_DIR/core/pipelines.sh"

ROOT="$(p_root)"
cd "$ROOT"

# ── Parsowanie argumentów ───────────────────────────────────
SUBCOMMAND="${1:-verify}"
CLASS="${2:-}"

# ── Nagłówek ────────────────────────────────────────────────
p_say "=== PIPELINE OPERATING SYSTEM: $SUBCOMMAND/$CLASS ==="

# ── Uruchomienie pipeline'a ─────────────────────────────────
# run_pipeline <id> — uruchamia pipeline przez jego skrypt (pipeline_script).
# Każde uruchomienie to GATE: po zakończeniu zapisuje evidence do StateStore
# (P0#1) i rejestruje pipeline_run. Pipeline bez evidence = 0 punktów.
PIPE_RUN_COUNT=0
PIPE_FAIL_COUNT=0

run_pipeline() {
  local id="$1"
  local script
  script="$AUTOMATION_DIR/$(pipeline_script "$id")"
  local class
  class="$(pipeline_class "$id")"
  local status
  status="$(pipeline_status "$id")"

  # PROPOSED pipeline'y nie są uruchamiane (tylko zarejestrowane w katalogu).
  if [ "$status" = "PROPOSED" ]; then
    p_info "pipeline $id" "PROPOSED — zarejestrowany, nie uruchamiany"
    return 0
  fi

  PIPE_RUN_COUNT=$((PIPE_RUN_COUNT+1))
  local start_ms end_ms duration_ms
  start_ms=$(date +%s%3N 2>/dev/null || echo 0)

  # FAIL-CLOSED (anti-drift): pipeline zadeklarowany w katalogu, a nieistniejący
  # = FAIL (BLOCKING), NIGDY skip.
  if [ -n "$script" ] && [ -f "$script" ]; then
    p_say ""
    p_say "────────────────────────────────────────────────────────────"
    p_say "PIPELINE: $id ($class)"
    p_say "────────────────────────────────────────────────────────────"
    bash "$script"
    local rc=$?
    if [ "$rc" -ne 0 ]; then
      PIPE_FAIL_COUNT=$((PIPE_FAIL_COUNT+1))
      p_fail "pipeline $id" BLOCKING "Pipeline zakończył się kodem $rc (oczekiwano 0)."
    fi
    # Evidence bridge (P0#1): każdy uruchomiony pipeline zapisuje wynik.
    p_evidence "pipeline:$id:rc=$rc" "pipeline" "$script"
  else
    # FAIL-CLOSED: brak pipeline'a = FAIL (BLOCKING), NIGDY skip.
    PIPE_FAIL_COUNT=$((PIPE_FAIL_COUNT+1))
    p_fail "pipeline $id" BLOCKING "Brak pipeline'a: $script (fail-closed — pipeline zadeklarowany, a nieistniejący)"
    p_evidence "pipeline:$id:MODULE-MISSING" "pipeline" "$script"
  fi

  end_ms=$(date +%s%3N 2>/dev/null || echo 0)
  duration_ms=$((end_ms - start_ms))
  # Rejestracja pipeline_run do StateStore (best-effort).
  p_register_run "$id" "$([ "$PIPE_FAIL_COUNT" -gt 0 ] && echo FAIL || echo PASS)" "$class" "$duration_ms"
}

# ── Uruchomienie pipeline'ów z respektowaniem zależności (DAG) ──
# Pipeline'y są uruchamiane w kolejności topologicznej: pipeline może być
# uruchomiony tylko jeśli wszystkie jego zależności (depends) już przeszły.
# Użycie: run_pipeline_dag <id> <visited>
declare -A PIPE_DONE=()
declare -A PIPE_VISITING=()

run_pipeline_dag() {
  local id="$1"
  # Cykl wykryty — FAIL (BLOCKING).
  if [ "${PIPE_VISITING[$id]:-}" = "1" ]; then
    PIPE_FAIL_COUNT=$((PIPE_FAIL_COUNT+1))
    p_fail "pipeline $id" BLOCKING "Wykryto cykl w zależnościach pipeline'ów (DAG)."
    return 1
  fi
  # Już uruchomiony — pomiń.
  if [ "${PIPE_DONE[$id]:-}" = "1" ]; then
    return 0
  fi
  PIPE_VISITING[$id]=1
  # Uruchom zależności najpierw.
  local deps
  deps="$(pipeline_depends "$id")"
  local dep
  for dep in ${deps//,/ }; do
    if [ -n "$dep" ]; then
      run_pipeline_dag "$dep"
    fi
  done
  PIPE_VISITING[$id]=0
  PIPE_DONE[$id]=1
  run_pipeline "$id"
}

# ── Uruchomienie pipeline'ów dla klasy ──────────────────────
# pipeline_class_modules() (z pipelines.sh) zwraca listę pipeline'ów
# dla danej klasy. To eliminuje FALSE GATE — KLASA jest respektowana.
run_class_modules() {
  local class="$1"
  local pipelines
  pipelines="$(pipeline_class_modules "$class")"
  local p
  for p in $pipelines; do
    run_pipeline_dag "$p"
  done
}

# ── Subkomendy ──────────────────────────────────────────────
case "$SUBCOMMAND" in
  verify)
    # FAST + STANDARD (pre-commit/pre-push)
    run_class_modules "FAST"
    run_class_modules "STANDARD"
    ;;
  audit)
    # DEEP (CI, niezależna weryfikacja)
    run_class_modules "DEEP"
    ;;
  release)
    # RELEASE (pełna certyfikacja baseline)
    run_class_modules "RELEASE"
    ;;
  deploy)
    # RELEASE + DEPLOYMENT (wdrożenie)
    run_class_modules "RELEASE"
    run_class_modules "DEEP"
    ;;
  certify)
    # CONTINUOUS (ciągła certyfikacja)
    run_class_modules "CONTINUOUS"
    ;;
  list)
    # Wypisz katalog pipeline'ów
    p_say ""
    p_say "=== PIPELINE CATALOG (${#PIPELINES[@]} pipeline'ów) ==="
    for entry in "${PIPELINES[@]}"; do
      eid="${entry%%|*}"
      rest="${entry#*|}"
      fam="${rest%%|*}"
      rest="${rest#*|}"
      scr="${rest%%|*}"
      rest="${rest#*|}"
      cls="${rest%%|*}"
      rest="${rest#*|}"
      st="${rest%%|*}"
      printf '  %-6s %-10s %-8s %-12s %s\n' "$eid" "$fam" "$cls" "$st" "$scr"
    done
    exit 0
    ;;
  *)
    p_say "Nieznana subkomenda: $SUBCOMMAND"
    p_say "Dostępne: verify | audit | release | deploy | certify | list"
    exit 2
    ;;
esac

# ── Podsumowanie ────────────────────────────────────────────
# Meta-gate PIPELINE-EVIDENCE-COMPLETE (P0#1): każdy uruchomiony pipeline
# MUSI zapisać evidence do StateStore. Pipeline bez evidence = 0 punktów.
p_evidence_complete "$PIPE_RUN_COUNT"

# p_module_exit wypisuje podsumowanie i propaguje status
# (exit 0 = PASS, exit 1 = FAIL) do procesu nadrzędnego.
p_module_exit
