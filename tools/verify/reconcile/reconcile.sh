#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# reconcile/reconcile.sh — AIGON Production Platform — Reconciliation Engine
# Moduł: RECONCILE ORCHESTRATOR
# Uruchamia wszystkie 4 warstwy (CANON/DRIFT/HISTORY/DEBT) i
# buduje master reconciliation table.
#
# Zasada: "Jedno wejście, wiele wyspecjalizowanych świadków"
#   ./tools/verify reconcile  → uruchamia wszystkie moduły
#   ./tools/verify drift      → tylko warstwa CANON/DRIFT
#   ./tools/verify history    → tylko warstwa HISTORY
#   ./tools/verify debt       → tylko warstwa DEBT
#
# Master reconciliation table:
#   DOMAIN × CANON/LOCAL/RUNTIME/NODES/HISTORY
#   + REPOSITORY STATUS header (Canonical %, Drift count,
#     Historical debt count, Unknown count, Nodes x/y,
#     Agents x/y, Reproducible, Security)
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"
# shellcheck source=../core/reconcile.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/reconcile.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== RECONCILE ORCHESTRATOR ==="
say "Model 4 warstw: CANON / DRIFT / HISTORY / DEBT"
say "Poziomy: L0 FILESYSTEM / L1 REPOSITORY / L2 RUNTIME / L3 CLUSTER / L4 HISTORY"
say ""

# ── Reset stanu master table ────────────────────────────────
recon_reset

# ── Baseline diff (BASELINE→CURRENT→EXPECTED→UNEXPECTED) ───
say "--- Baseline diff ---"
# Delegowane do reconcile/baseline.sh
info "RECON-BASELINE" "Delegowane do reconcile/baseline.sh."

# ── Warstwa CANON (Source of Truth) ─────────────────────────
say "--- Warstwa CANON (Source of Truth) ---"
recon_begin "CANON"
recon_cell "CANON" "SoT"
recon_cell "LOCAL" "repo"
recon_cell "RUNTIME" "n/a"
recon_cell "NODES" "n/a"
recon_cell "HISTORY" "n/a"
recon_end

# Sprawdź SoT
if [ -f "./SOURCE-OF-TRUTH.md" ]; then
  sot_status=$(grep -E 'STATUS:' ./SOURCE-OF-TRUTH.md | head -1 | sed 's/.*STATUS:[[:space:]]*//')
  if [ -z "$sot_status" ] || [ "$sot_status" = "UNDEFINED" ]; then
    warn "RECON-CANON SoT STATUS" "SOURCE-OF-TRUTH.md STATUS: $sot_status — wymaga decyzji."
  else
    pass "RECON-CANON SoT STATUS" BLOCKING "SOURCE-OF-TRUTH.md STATUS: $sot_status"
  fi
else
  fail "RECON-CANON SoT" BLOCKING "Brak SOURCE-OF-TRUTH.md."
fi

# ── Warstwa DRIFT (deklaracja vs rzeczywistość) ─────────────
say ""
say "--- Warstwa DRIFT (deklaracja vs rzeczywistość) ---"
recon_begin "DRIFT"
recon_cell "CANON" "kanon"
recon_cell "LOCAL" "repo"
recon_cell "RUNTIME" "n/a"
recon_cell "NODES" "n/a"
recon_cell "HISTORY" "n/a"
recon_end

# Delegowane do drift/drift.sh
info "RECON-DRIFT" "Delegowane do drift/drift.sh."

# ── Warstwa HISTORY (legacy/deprecated/archived) ────────────
say ""
say "--- Warstwa HISTORY (legacy/deprecated/archived) ---"
recon_begin "HISTORY"
recon_cell "CANON" "kanon"
recon_cell "LOCAL" "repo"
recon_cell "RUNTIME" "n/a"
recon_cell "NODES" "n/a"
recon_cell "HISTORY" "archive"
recon_end

# Delegowane do history/history.sh
info "RECON-HISTORY" "Delegowane do history/history.sh."

# ── Warstwa DEBT (dług świadomy vs ukryty) ──────────────────
say ""
say "--- Warstwa DEBT (dług świadomy vs ukryty) ---"
recon_begin "DEBT"
recon_cell "CANON" "kanon"
recon_cell "LOCAL" "repo"
recon_cell "RUNTIME" "n/a"
recon_cell "NODES" "n/a"
recon_cell "HISTORY" "debt"
recon_end

# Delegowane do debt/debt.sh
info "RECON-DEBT" "Delegowane do debt/debt.sh."

# ── Master reconciliation table ─────────────────────────────
say ""
recon_print_table

# ── REPOSITORY STATUS header ────────────────────────────────
say "=== REPOSITORY STATUS ==="
# Canonical % — ile README ma wszystkie 12 sekcji (delegowane do drift)
# Drift count — liczba FAIL/WARN z warstwy DRIFT
# Historical debt count — liczba elementów w archive/
# Unknown count — liczba elementów bez klasyfikacji
# Nodes x/y — n/a (repo foundation, brak Runtime)
# Agents x/y — n/a
# Reproducible — n/a (brak build)
# Security — delegowane do security

CANONICAL_PCT="n/a"
DRIFT_COUNT="$VERIFY_FAIL"
DEBT_COUNT=$(find ./archive -type f -not -name 'README.md' -not -name '.gitkeep' 2>/dev/null | wc -l)
UNKNOWN_COUNT="n/a"
NODES="0/0"
AGENTS="0/0"
REPRODUCIBLE="n/a"
SECURITY="n/a"

printf '%-22s %s\n' "Canonical %" "$CANONICAL_PCT"
printf '%-22s %s\n' "Drift count" "$DRIFT_COUNT"
printf '%-22s %s\n' "Historical debt count" "$DEBT_COUNT"
printf '%-22s %s\n' "Unknown count" "$UNKNOWN_COUNT"
printf '%-22s %s\n' "Nodes" "$NODES"
printf '%-22s %s\n' "Agents" "$AGENTS"
printf '%-22s %s\n' "Reproducible" "$REPRODUCIBLE"
printf '%-22s %s\n' "Security" "$SECURITY"

verify_module_exit
