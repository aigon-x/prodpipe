#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# display.sh — Visual Pipeline Display — rdzeń renderowania (terminal ANSI)
# ─────────────────────────────────────────────────────────────
# Renderuje Pipeline Operating System (P-001..P-098) jako gęsty,
# techniczny widok terminala. Czyta kanoniczny katalog z
# tools/automation/core/pipelines.sh (GENEROWANY z pipelines.yaml).
#
# Funkcje (wszystkie wypisują na stdout):
#   d_render_header        — nagłówek z metadanymi
#   d_render_families      — lista 13 rodzin z licznikami
#   d_render_stages        — wszystkie pipeline'y P-001..P-098 z metadanymi
#   d_render_deps          — zależności jako ASCII graph
#   d_render_gates         — pokrycie gate'ów (GATE-001..GATE-042) + evidence
#   d_render_status        — status/evidence per pipeline
#   d_render_contract      — 8-fazowy Pipeline Contract
#   d_render_all           — wszystko (header + families + stages + deps + gates + status)
#
# Zasady:
#   * set -u (jak cały projekt).
#   * NO FALSE GREEN — brak danych = NOT_APPLICABLE, NIGDY PASS.
#   * FAIL-CLOSED — brak źródła (pipelines.sh) = FAIL (BLOCKING).
#   * Komentarze po polsku, identyfikatory po angielsku.
# ─────────────────────────────────────────────────────────────
set -u

# ── Ścieżki ─────────────────────────────────────────────────
# display.sh jest w lib/, więc:
#   BASH_SOURCE[0] = lib/display.sh
#   dirname        = lib
#   ..             = display (katalog narzędzia)
#   ../..          = automation
D_DISPLAY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D_AUTOMATION_DIR="$(cd "$D_DISPLAY_DIR/.." && pwd)"
D_REPO_ROOT="$(cd "$D_AUTOMATION_DIR/../.." && pwd)"

# ── Wczytaj core (lib.sh + pipelines.sh) ────────────────────
. "$D_AUTOMATION_DIR/core/lib.sh"
. "$D_AUTOMATION_DIR/core/pipelines.sh"
# ── Wczytaj paletę kolorów ──────────────────────────────────
. "$D_DISPLAY_DIR/lib/colors.sh"

# ── Konfiguracja display (config/display.yaml) ──────────────
# Fallback do wbudowanych wartości, jeśli YAML nie jest dostępny.
D_CONFIG_FILE="$D_REPO_ROOT/config/display.yaml"
D_THEME="dark"
D_EMPHASIS="dense"
D_FAMILY_ORDER="PRODUCT DESIGN SECURITY CODE BUILD DEPLOYMENT RUNTIME RECOVERY GTM AI OFFENSIVE-SECURITY HUMAN-SIMULATION SIMULATION"
D_CLASS_ORDER="FAST STANDARD DEEP RELEASE CONTINUOUS"

# ── Katalog evidence gate'ów ────────────────────────────────
D_EVIDENCE_DIR="$D_REPO_ROOT/artifacts/evidence/gates"

# ── Parsowanie config/display.yaml (best-effort) ────────────
# Czyta tylko proste klucze: theme, emphasis, family_order, class_order.
# Brak pliku = fallback do wbudowanych wartości (NIE jest to FAIL —
# display to narzędzie wizualne, nie gate).
d_load_config() {
  if [ ! -f "$D_CONFIG_FILE" ]; then
    return 0
  fi
  local line key val
  while IFS= read -r line; do
    case "$line" in
      \#*|'') continue ;;
    esac
    key="${line%%:*}"
    val="${line#*:}"
    val="${val# }"
    val="${val%\"}"
    val="${val#\"}"
    case "$key" in
      theme)      [ -n "$val" ] && D_THEME="$val" ;;
      emphasis)   [ -n "$val" ] && D_EMPHASIS="$val" ;;
      family_order) [ -n "$val" ] && D_FAMILY_ORDER="$val" ;;
      class_order)  [ -n "$val" ] && D_CLASS_ORDER="$val" ;;
    esac
  done < "$D_CONFIG_FILE"
}

# ── Parsowanie wpisu PIPELINES ──────────────────────────────
# Format: <id>|<family>|<script>|<class>|<status>|<depends>|<contract>
# Użycie: d_parse_entry <entry> <field>
#   field: id|family|script|class|status|depends|contract
d_parse_entry() {
  local entry="$1" field="$2"
  local id family script class status depends contract
  id="${entry%%|*}"
  local rest="${entry#*|}"
  family="${rest%%|*}"; rest="${rest#*|}"
  script="${rest%%|*}"; rest="${rest#*|}"
  class="${rest%%|*}";  rest="${rest#*|}"
  status="${rest%%|*}"; rest="${rest#*|}"
  depends="${rest%%|*}"; rest="${rest#*|}"
  contract="${rest%%|*}"
  case "$field" in
    id)       echo "$id" ;;
    family)   echo "$family" ;;
    script)   echo "$script" ;;
    class)    echo "$class" ;;
    status)   echo "$status" ;;
    depends)  echo "$depends" ;;
    contract) echo "$contract" ;;
  esac
}

# ── Licznik pipeline'ów w rodzinie ──────────────────────────
d_family_count() {
  local family="$1" count=0
  local entry
  for entry in "${PIPELINES[@]}"; do
    if [ "$(d_parse_entry "$entry" family)" = "$family" ]; then
      count=$((count+1))
    fi
  done
  echo "$count"
}

# ── Licznik pipeline'ów w klasie ────────────────────────────
d_class_count() {
  local class="$1" count=0
  local entry
  for entry in "${PIPELINES[@]}"; do
    if [ "$(d_parse_entry "$entry" class)" = "$class" ]; then
      count=$((count+1))
    fi
  done
  echo "$count"
}

# ── Status evidence dla gate'a ──────────────────────────────
# Czyta artifacts/evidence/gates/GATE-###.evidence.
# Zwraca: PASS | FAIL | NOT_APPLICABLE (brak pliku = NOT_APPLICABLE).
d_gate_evidence_status() {
  local gate_id="$1"
  local file="$D_EVIDENCE_DIR/$gate_id.evidence"
  if [ ! -f "$file" ]; then
    echo "NOT_APPLICABLE"
    return 0
  fi
  local status=""
  status="$(grep -E '^status=' "$file" | head -n1 | cut -d= -f2)"
  if [ -z "$status" ]; then
    echo "NOT_APPLICABLE"
  else
    echo "$status"
  fi
}

# ── Status evidence dla pipeline'a ──────────────────────────
# Pipeline'y nie mają osobnych plików evidence w artifacts/evidence/gates/
# (to domena gate'ów). Dla pipeline'ów raportujemy NOT_APPLICABLE, chyba że
# istnieje evidence w StateStore (best-effort). NO FALSE GREEN.
d_pipeline_evidence_status() {
  local pid="$1"
  local db="${PIPE_STATE_DB:-}"
  if [ -z "$db" ]; then
    db="$D_REPO_ROOT/system/control-plane/state/data/canonical-state.db"
  fi
  if [ ! -f "$db" ] || ! command -v sqlite3 >/dev/null 2>&1; then
    echo "NOT_APPLICABLE"
    return 0
  fi
  local row
  row="$(sqlite3 "$db" "SELECT status FROM pipeline_runs WHERE pipeline_id='$pid' ORDER BY rowid DESC LIMIT 1;" 2>/dev/null)"
  if [ -z "$row" ]; then
    echo "NOT_APPLICABLE"
  else
    echo "$row"
  fi
}

# ── Renderowanie nagłówka ───────────────────────────────────
d_render_header() {
  local total="${#PIPELINES[@]}"
  local implemented=0 proposed=0
  local entry
  for entry in "${PIPELINES[@]}"; do
    if [ "$(d_parse_entry "$entry" status)" = "IMPLEMENTED" ]; then
      implemented=$((implemented+1))
    else
      proposed=$((proposed+1))
    fi
  done
  p_say ""
  p_sayc "╔══════════════════════════════════════════════════════════════════╗" "$D_C_CYAN"
  p_sayc "║  PIPELINE OPERATING SYSTEM — VISUAL DISPLAY                       ║" "$D_C_CYAN"
  p_sayc "║  Metadata-driven pipeline catalog (P-001..P-098)                  ║" "$D_C_CYAN"
  p_sayc "╚══════════════════════════════════════════════════════════════════╝" "$D_C_CYAN"
  p_say ""
  p_say "  Total pipelines : $total"
  p_say "  Implemented     : $(d_paint "$D_C_BRIGHT_GREEN" "$implemented")"
  p_say "  Proposed        : $(d_paint "$D_C_BRIGHT_YELLOW" "$proposed")"
  p_say "  Theme           : $D_THEME"
  p_say "  Emphasis        : $D_EMPHASIS"
  p_say "  Source of truth : config/canonical/pipelines.yaml"
  p_say "  Generated       : tools/automation/core/pipelines.sh"
  p_say ""
}

# ── Renderowanie 8-fazowego Pipeline Contract ───────────────
d_render_contract() {
  p_say ""
  p_sayc "── PIPELINE CONTRACT (8 faz) ───────────────────────────────────────" "$D_C_CYAN"
  p_say ""
  local phase color
  for phase in $PIPE_CONTRACT_PHASES; do
    case "$phase" in
      DISCOVER) color="$D_C_BRIGHT_CYAN" ;;
      CONTRACT) color="$D_C_BRIGHT_BLUE" ;;
      EXECUTE)  color="$D_C_BRIGHT_GREEN" ;;
      TEST)     color="$D_C_BRIGHT_YELLOW" ;;
      EVIDENCE) color="$D_C_BRIGHT_MAGENTA" ;;
      VERIFY)   color="$D_C_BRIGHT_RED" ;;
      REGISTER) color="$D_C_CYAN" ;;
      REPORT)   color="$D_C_BRIGHT_WHITE" ;;
      *)        color="$D_C_WHITE" ;;
    esac
    printf '  %s %s\n' "$(d_paint "$color" "$(printf '%-10s' "$phase")")" "→"
  done
  p_say ""
  p_say "  Każdy pipeline realizuje wszystkie 8 faz (DISCOVER → REPORT)."
  p_say ""
}

# ── Renderowanie rodzin ─────────────────────────────────────
d_render_families() {
  p_say ""
  p_sayc "── PIPELINE FAMILIES (13) ──────────────────────────────────────────" "$D_C_CYAN"
  p_say ""
  local family color count
  for family in $D_FAMILY_ORDER; do
    color="$(d_family_color "$family")"
    count="$(d_family_count "$family")"
    printf '  %s %s\n' "$(d_paint "$color" "$(printf '%-20s' "$family")")" "$(d_paint "$D_C_BRIGHT_WHITE" "$(printf '%3d' "$count")") pipeline'ów"
  done
  p_say ""
}

# ── Renderowanie wszystkich pipeline'ów (stages) ────────────
d_render_stages() {
  p_say ""
  p_sayc "── PIPELINE STAGES (P-001..P-098) ──────────────────────────────────" "$D_C_CYAN"
  p_say ""
  p_say "  ID      FAMILY              CLASS       STATUS      SCRIPT"
  p_say "  ──────  ──────────────────  ──────────  ──────────  ─────────────────────────────"
  local entry id family script class status
  for entry in "${PIPELINES[@]}"; do
    id="$(d_parse_entry "$entry" id)"
    family="$(d_parse_entry "$entry" family)"
    script="$(d_parse_entry "$entry" script)"
    class="$(d_parse_entry "$entry" class)"
    status="$(d_parse_entry "$entry" status)"
    printf '  %s %s %s %s %s\n' \
      "$(d_paint "$D_C_BRIGHT_WHITE" "$(printf '%-6s' "$id")")" \
      "$(d_paint "$(d_family_color "$family")" "$(printf '%-18s' "$family")")" \
      "$(d_paint "$(d_class_color "$class")" "$(printf '%-10s' "$class")")" \
      "$(d_paint "$(d_status_color "$status")" "$(printf '%-10s' "$status")")" \
      "$(d_paint "$D_C_DIM" "$script")"
  done
  p_say ""
}

# ── Renderowanie zależności (ASCII graph) ───────────────────
# Dla każdego pipeline'a z zależnościami wypisuje:  <id> ──▶ <dep>
d_render_deps() {
  p_say ""
  p_sayc "── PIPELINE DEPENDENCIES (ASCII graph) ─────────────────────────────" "$D_C_CYAN"
  p_say ""
  p_say "  (edge: <pipeline> ──▶ <zależność>)"
  p_say ""
  local entry id depends dep
  for entry in "${PIPELINES[@]}"; do
    id="$(d_parse_entry "$entry" id)"
    depends="$(d_parse_entry "$entry" depends)"
    if [ -z "$depends" ]; then
      printf '  %s %s\n' "$(d_paint "$D_C_BRIGHT_WHITE" "$(printf '%-6s' "$id")")" "$(d_paint "$D_C_DIM" "(root — brak zależności)")"
    else
      local dep
      for dep in ${depends//,/ }; do
        printf '  %s %s %s\n' \
          "$(d_paint "$D_C_BRIGHT_WHITE" "$(printf '%-6s' "$id")")" \
          "$(d_paint "$D_C_CYAN" "──▶")" \
          "$(d_paint "$D_C_BRIGHT_CYAN" "$dep")"
      done
    fi
  done
  p_say ""
}

# ── Renderowanie pokrycia gate'ów ───────────────────────────
# Czyta GATE_REGISTRY (registry.sh) + evidence files.
# Brak evidence = NOT_APPLICABLE (NO FALSE GREEN).
d_render_gates() {
  p_say ""
  p_sayc "── GATE COVERAGE (GATE-001..GATE-042) ──────────────────────────────" "$D_C_CYAN"
  p_say ""
  local registry="$D_REPO_ROOT/tools/verify/gates/registry.sh"
  if [ ! -f "$registry" ]; then
    p_say "  (registry.sh niedostępny — brak danych o gate'ach)"
    p_say ""
    return 0
  fi
  # Wczytaj GATE_REGISTRY (tab-separated). Nie źródłujemy całego pliku —
  # tylko wyciągamy linie GATE_REGISTRY.
  local gate_id domain status color
  local i
  for i in $(seq 1 42); do
    gate_id="$(printf 'GATE-%03d' "$i")"
    domain="$(grep -E "'$gate_id' '" "$registry" | head -n1 | awk -F"'" '{print $4}')"
    status="$(d_gate_evidence_status "$gate_id")"
    color="$(d_verdict_color "$status")"
    printf '  %s %s %s\n' \
      "$(d_paint "$D_C_BRIGHT_WHITE" "$(printf '%-9s' "$gate_id")")" \
      "$(d_paint "$D_C_DIM" "$(printf '%-22s' "${domain:-?}")")" \
      "$(d_paint "$color" "$(printf '%-14s' "$status")")"
  done
  p_say ""
  p_say "  Legenda: PASS = evidence PASS | FAIL = evidence FAIL | NOT_APPLICABLE = brak evidence"
  p_say ""
}

# ── Renderowanie statusu/evidence per pipeline ──────────────
d_render_status() {
  p_say ""
  p_sayc "── PIPELINE STATUS / EVIDENCE ──────────────────────────────────────" "$D_C_CYAN"
  p_say ""
  p_say "  ID      STATUS      EVIDENCE        SCRIPT"
  p_say "  ──────  ──────────  ──────────────  ─────────────────────────────"
  local entry id status ev color
  for entry in "${PIPELINES[@]}"; do
    id="$(d_parse_entry "$entry" id)"
    status="$(d_parse_entry "$entry" status)"
    ev="$(d_pipeline_evidence_status "$id")"
    color="$(d_verdict_color "$ev")"
    printf '  %s %s %s %s\n' \
      "$(d_paint "$D_C_BRIGHT_WHITE" "$(printf '%-6s' "$id")")" \
      "$(d_paint "$(d_status_color "$status")" "$(printf '%-10s' "$status")")" \
      "$(d_paint "$color" "$(printf '%-14s' "$ev")")" \
      "$(d_paint "$D_C_DIM" "$(d_parse_entry "$entry" script)")"
  done
  p_say ""
  p_say "  NO FALSE GREEN: brak evidence = NOT_APPLICABLE (nigdy PASS)."
  p_say ""
}

# ── Renderowanie wszystkiego ────────────────────────────────
d_render_all() {
  d_load_config
  d_render_header
  d_render_contract
  d_render_families
  d_render_stages
  d_render_deps
  d_render_gates
  d_render_status
}
