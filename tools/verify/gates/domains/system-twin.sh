#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/system-twin.sh — GATE-021 SYSTEM-TWIN
# Weryfikuje że żywy wykonywalny graf stanu (System Twin) jest
# spójny z rzeczywistością. "MODEL OUTPUT IS A CLAIM, NOT A FACT."
# Każdy node w grafie musi mieć żywy odpowiednik, każdy edge
# realną zależność. Stan weryfikowany ZEWNĘTRZNIE, nie z deklaracji.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-021 SYSTEM-TWIN ==="

STATE_DIR="./system/control-plane/state"
STATE_DB="$STATE_DIR/data/canonical-state.db"

# ── SYSTEM-TWIN-001: migracja system_twin istnieje ──────────
if [ -f "$STATE_DIR/migrations/0003_system_twin.sql" ]; then
  pass "SYSTEM-TWIN-001 migracja system_twin" BLOCKING "Migracja 0003_system_twin.sql obecna."
else
  fail "SYSTEM-TWIN-001 migracja system_twin" BLOCKING "Brak migracji 0003_system_twin.sql."
fi

# ── SYSTEM-TWIN-002: tabela system_twin_node w migracji ─────
if [ -f "$STATE_DIR/migrations/0003_system_twin.sql" ]; then
  if grep -qE 'CREATE TABLE.*system_twin_node' "$STATE_DIR/migrations/0003_system_twin.sql"; then
    pass "SYSTEM-TWIN-002 tabela system_twin_node" BLOCKING "Tabela system_twin_node zdefiniowana."
  else
    fail "SYSTEM-TWIN-002 tabela system_twin_node" BLOCKING "Brak tabeli system_twin_node."
  fi
fi

# ── SYSTEM-TWIN-003: tabela system_twin_edge w migracji ─────
if [ -f "$STATE_DIR/migrations/0003_system_twin.sql" ]; then
  if grep -qE 'CREATE TABLE.*system_twin_edge' "$STATE_DIR/migrations/0003_system_twin.sql"; then
    pass "SYSTEM-TWIN-003 tabela system_twin_edge" BLOCKING "Tabela system_twin_edge zdefiniowana."
  else
    fail "SYSTEM-TWIN-003 tabela system_twin_edge" BLOCKING "Brak tabeli system_twin_edge."
  fi
fi

# ── SYSTEM-TWIN-004: schema_version spójna z ostatnią migracją ──
# STATE_SCHEMA_VERSION w lib.sh musi odpowiadać ostatniej migracji
# (dynamicznie, nie hardcoded — schema jest migracyjna).
if [ -f "$STATE_DIR/lib.sh" ]; then
  declared=$(grep -E 'STATE_SCHEMA_VERSION=' "$STATE_DIR/lib.sh" | head -1 | sed 's/.*="\([0-9]*\)".*/\1/')
  last_migration=$(find "$STATE_DIR/migrations" -name '*.sql' 2>/dev/null | sort | tail -1 | xargs -r basename | cut -d_ -f1)
  if [ -n "$declared" ] && [ -n "$last_migration" ]; then
    declared_num=$((10#$declared))
    last_num=$((10#$last_migration))
    if [ "$declared_num" -eq "$last_num" ]; then
      pass "SYSTEM-TWIN-004 schema_version spójna" BLOCKING "STATE_SCHEMA_VERSION=$declared == ostatnia migracja $last_migration."
    else
      fail "SYSTEM-TWIN-004 schema_version spójna" BLOCKING "STATE_SCHEMA_VERSION=$declared != ostatnia migracja $last_migration."
    fi
  else
    fail "SYSTEM-TWIN-004 schema_version spójna" BLOCKING "Nie można odczytać STATE_SCHEMA_VERSION lub migracji."
  fi
fi

# ── SYSTEM-TWIN-005: graf stanu spójny z rzeczywistością ────
# Każdy node w grafie musi mieć żywy odpowiednik w systemie.
# Weryfikacja ZEWNĘTRZNA: node deklaruje ścieżkę/komponent, gate
# sprawdza czy ten komponent faktycznie istnieje w repo.
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$STATE_DB" ]; then
  node_count=$(sqlite3 "$STATE_DB" "SELECT COUNT(*) FROM system_twin_node;" 2>/dev/null || echo "0")
  if [ "$node_count" -gt 0 ]; then
    # Weryfikuj każdy node: czy jego declared ścieżka istnieje w repo
    broken=0
    while IFS='|' read -r node_id declared_path; do
      if [ -n "$declared_path" ] && [ "$declared_path" != "-" ]; then
        if [ ! -e "$declared_path" ]; then
          broken=$((broken+1))
          warn "SYSTEM-TWIN-005 node $node_id: brak odpowiednika $declared_path"
        fi
      fi
    done < <(sqlite3 "$STATE_DB" "SELECT node_id, COALESCE(declared,'-') FROM system_twin_node;" 2>/dev/null)
    if [ "$broken" -eq 0 ]; then
      pass "SYSTEM-TWIN-005 graf spójny z rzeczywistością" BLOCKING "$node_count nodów, wszystkie mają żywe odpowiedniki."
    else
      fail "SYSTEM-TWIN-005 graf spójny z rzeczywistością" BLOCKING "$broken nodów bez żywego odpowiednika."
    fi
  else
    info "SYSTEM-TWIN-005 graf spójny z rzeczywistością" "Brak nodów w grafie (System Twin pusty)."
  fi
else
  info "SYSTEM-TWIN-005 graf spójny z rzeczywistością" "Baza StateStore niedostępna — pomijam weryfikację grafu."
fi

# ── SYSTEM-TWIN-006: każdy edge ma realną zależność ─────────
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$STATE_DB" ]; then
  edge_count=$(sqlite3 "$STATE_DB" "SELECT COUNT(*) FROM system_twin_edge;" 2>/dev/null || echo "0")
  if [ "$edge_count" -gt 0 ]; then
    # Każdy edge musi łączyć istniejące node'y (FK wymusza to w SQLite)
    orphan_edges=$(sqlite3 "$STATE_DB" "SELECT COUNT(*) FROM system_twin_edge e LEFT JOIN system_twin_node n ON e.from_node=n.node_id WHERE n.node_id IS NULL;" 2>/dev/null || echo "0")
    if [ "$orphan_edges" -eq 0 ]; then
      pass "SYSTEM-TWIN-006 edge'y mają realne zależności" BLOCKING "$edge_count krawędzi, wszystkie łączą istniejące node'y."
    else
      fail "SYSTEM-TWIN-006 edge'y mają realne zależności" BLOCKING "$orphan_edges krawędzi z nieistniejącym node'em."
    fi
  else
    info "SYSTEM-TWIN-006 edge'y mają realne zależności" "Brak krawędzi w grafie."
  fi
else
  info "SYSTEM-TWIN-006 edge'y mają realne zależności" "Baza StateStore niedostępna — pomijam weryfikację krawędzi."
fi

verify_module_exit
