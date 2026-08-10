#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# core/reconcile.sh — AIGON Production Platform — Reconciliation Engine
# Wspólne funkcje dla modułów DRIFT / HISTORY / DEBT / RECONCILE.
#
# Model 4 warstw:
#   CANON   — zgodność z Source of Truth (kanon)
#   DRIFT   — deklaracja vs kod vs Runtime vs deploy vs node
#   HISTORY — legacy / deprecated / stale / archiwizowane
#   DEBT    — dług świadomy vs ukryty
#
# Statusy elementu (Historical Debt Scanner):
#   CURRENT        — aktywny, zgodny z kanonem
#   CANONICAL      — zdefiniowany w kanonie (SoT)
#   DEPRECATED     — oznaczony jako deprecated
#   QUARANTINED    — wyizolowany, nieaktywny
#   ARCHIVED       — przeniesiony do archive/
#   ALLOWED_LEGACY — świadomie dozwolony legacy
#   UNKNOWN        — nie można ustalić (CZERWONY)
#   DRIFT          — rozjazd z kanonem (CZERWONY)
#
# Poziomy L0-L4:
#   L0 FILESYSTEM — repo/pliki/symlinki/uprawnienia/generated
#   L1 REPOSITORY — git/source/config/docs/deps/Docker
#   L2 RUNTIME    — services/registry/ports/networks/telemetry/agents
#   L3 CLUSTER    — node↔node/images/versions/ABI/SoT/config/identity
#   L4 HISTORY    — legacy/deprecated/archived/migrations/stale refs
# ─────────────────────────────────────────────────────────────
set -u

# ── Globalny stan master reconciliation table ───────────────
# Każdy wiersz: DOMAIN|CANON|LOCAL|RUNTIME|NODES|HISTORY
RECON_TABLE=""
RECON_DOMAIN=""

# ── Rozpoczęcie wiersza master table ────────────────────────
# Użycie: recon_begin <DOMAIN>
recon_begin() {
  RECON_DOMAIN="$1"
}

# ── Dodanie komórki do bieżącego wiersza ────────────────────
# Użycie: recon_cell <COLUMN> <VALUE>
#   COLUMN: CANON | LOCAL | RUNTIME | NODES | HISTORY
recon_cell() {
  local col="$1" val="$2"
  RECON_TABLE="$RECON_TABLE|$col=$val"
}

# ── Zakończenie wiersza ─────────────────────────────────────
recon_end() {
  RECON_TABLE="$RECON_TABLE
$RECON_DOMAIN"
}

# ── Wypisanie master reconciliation table ───────────────────
recon_print_table() {
  say ""
  say "=== MASTER RECONCILIATION TABLE ==="
  say "DOMAIN × CANON/LOCAL/RUNTIME/NODES/HISTORY"
  say ""
  printf '%-22s %-10s %-10s %-10s %-10s %-10s\n' \
    "DOMAIN" "CANON" "LOCAL" "RUNTIME" "NODES" "HISTORY"
  printf '%-22s %-10s %-10s %-10s %-10s %-10s\n' \
    "------" "-----" "-----" "-------" "-----" "-------"
  local line
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local domain="${line%%|*}"
    local cells="${line#*|}"
    local canon="" localv="" runtime="" nodes="" history=""
    local cell
    IFS='|' read -ra cellarr <<< "$cells"
    for cell in "${cellarr[@]}"; do
      case "$cell" in
        CANON=*)  canon="${cell#CANON=}" ;;
        LOCAL=*)  localv="${cell#LOCAL=}" ;;
        RUNTIME=*) runtime="${cell#RUNTIME=}" ;;
        NODES=*)  nodes="${cell#NODES=}" ;;
        HISTORY=*) history="${cell#HISTORY=}" ;;
      esac
    done
    printf '%-22s %-10s %-10s %-10s %-10s %-10s\n' \
      "$domain" "$canon" "$localv" "$runtime" "$nodes" "$history"
  done <<< "$RECON_TABLE"
  say ""
}

# ── Klasyfikacja statusu elementu ───────────────────────────
# Użycie: recon_status <STATUS> <NAME> [DETAIL]
#   UNKNOWN i DRIFT są CZERWONE (fail), reszta to info/pass.
recon_status() {
  local status="$1" name="$2" detail="${3:-}"
  case "$status" in
    UNKNOWN)
      fail "RECON-UNKNOWN $name" BLOCKING "Status UNKNOWN (czerwony): $detail"
      ;;
    DRIFT)
      fail "RECON-DRIFT $name" BLOCKING "Status DRIFT (czerwony): $detail"
      ;;
    CURRENT|CANONICAL)
      pass "RECON-$status $name" BLOCKING "$detail"
      ;;
    DEPRECATED|QUARANTINED|ARCHIVED|ALLOWED_LEGACY)
      info "RECON-$status $name" "$detail"
      ;;
    *)
      info "RECON-$status $name" "$detail"
      ;;
  esac
}

# ── Baseline diff ───────────────────────────────────────────
# Użycie: recon_baseline_diff <BASELINE> <CURRENT> <EXPECTED> <UNEXPECTED>
#   BASELINE  — stan z tagu BASELINE-0.1.0
#   CURRENT   — stan obecny
#   EXPECTED  — zmiany oczekiwane (zgodne z kanonem)
#   UNEXPECTED— zmiany nieoczekiwane (DRIFT / HISTORY DEBT)
recon_baseline_diff() {
  local baseline="$1" current="$2" expected="$3" unexpected="$4"
  say ""
  say "=== BASELINE DIFF ==="
  say "BASELINE : $baseline"
  say "CURRENT  : $current"
  say "EXPECTED : $expected"
  say "UNEXPECTED: $unexpected"
  say ""
  if [ -n "$unexpected" ] && [ "$unexpected" != "none" ]; then
    fail "RECON-BASELINE Unexpected changes" BLOCKING "$unexpected"
  else
    pass "RECON-BASELINE No unexpected changes" BLOCKING
  fi
}

# ── Reset stanu (dla wielokrotnych uruchomień) ──────────────
recon_reset() {
  RECON_TABLE=""
  RECON_DOMAIN=""
}
