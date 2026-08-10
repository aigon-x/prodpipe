#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# lib/graphs.sh — MERMAID GRAPH GENERATOR
# Generuje katalog grafów Mermaid (docs/graphs/) z kanonicznego
# modelu projektu (project-model.json). JEDEN model → wiele widoków.
#
# Grafy: architecture, gates, pipelines, documentation,
# traceability, configuration, dependencies, evidence, temporal,
# tasks, findings, source-of-truth, full-system + README.md.
#
# Deterministic: każdy graf jest generowany z posortowanych danych.
# ─────────────────────────────────────────────────────────────
set -u

# ── Katalog wyjściowy grafów ────────────────────────────────
GRAPHS_DIR="$OUT_GRAPHS"

# ── Nagłówek wspólny dla grafów ─────────────────────────────
graphs_header() {
  printf '%% Wygenerowano z kanonicznego modelu projektu (project-model.json).\n'
  printf '%% Deterministic — nie edytuj ręcznie.\n'
}

# ── Graf: architektura (komponenty + relacje) ───────────────
graphs_architecture() {
  local out="$GRAPHS_DIR/architecture.mmd"
  {
    graphs_header
    printf 'graph TD\n'
    printf '  subgraph PROD["Prod-ready"]\n'
    while IFS= read -r d; do
      [ -n "$d" ] || continue
      printf '    %s["%s"]\n' "$(graphs_node_id "$d")" "$d"
    done < "$EXPLORE_WORK/dirs.txt"
    printf '  end\n'
    printf '  PROD -->|"kanoniczny model"| MODEL["project-model.json"]\n'
  } > "$out"
}

# ── Graf: gate'y (gate → evidence) ──────────────────────────
graphs_gates() {
  local out="$GRAPHS_DIR/gates.mmd"
  {
    graphs_header
    printf 'graph LR\n'
    while IFS= read -r gid; do
      [ -n "$gid" ] || continue
      local ev="BRAK"
      [ -f "$ROOT/artifacts/evidence/gates/$gid.evidence" ] && ev="TAK"
      printf '  %s["%s"] -->|"evidence: %s"| E%s["%s.evidence"]\n' \
        "$(graphs_node_id "$gid")" "$gid" "$ev" "$(graphs_node_id "$gid")" "$gid"
    done < "$EXPLORE_WORK/gates.txt"
  } > "$out"
}

# ── Graf: pipeline'y (zależności) ───────────────────────────
graphs_pipelines() {
  local out="$GRAPHS_DIR/pipelines.mmd"
  {
    graphs_header
    printf 'graph LR\n'
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      local pid depends
      pid="$(printf '%s' "$line" | cut -d'|' -f1)"
      depends="$(printf '%s' "$line" | cut -d'|' -f6)"
      if [ -n "$depends" ] && [ "$depends" != "-" ]; then
        printf '  %s["%s"] -->|"depends"| %s["%s"]\n' \
          "$(graphs_node_id "$pid")" "$pid" "$(graphs_node_id "$depends")" "$depends"
      else
        printf '  %s["%s"]\n' "$(graphs_node_id "$pid")" "$pid"
      fi
    done < "$EXPLORE_WORK/pipelines.txt"
  } > "$out"
}

# ── Graf: dokumentacja (drzewo docs/) ───────────────────────
graphs_documentation() {
  local out="$GRAPHS_DIR/documentation.mmd"
  {
    graphs_header
    printf 'graph TD\n'
    printf '  DOCS["docs/"]\n'
    while IFS= read -r doc; do
      [ -n "$doc" ] || continue
      local section
      section="$(printf '%s' "$doc" | cut -d/ -f2)"
      printf '  DOCS --> S%s["%s"]\n' "$(graphs_node_id "$section")" "$section"
      printf '  S%s --> D%s["%s"]\n' "$(graphs_node_id "$section")" "$(graphs_node_id "$doc")" "$(basename "$doc")"
    done < "$EXPLORE_WORK/docs.txt"
  } > "$out"
}

# ── Graf: traceability (pipeline → gate → evidence) ─────────
graphs_traceability() {
  local out="$GRAPHS_DIR/traceability.mmd"
  {
    graphs_header
    printf 'graph LR\n'
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      local pid script
      pid="$(printf '%s' "$line" | cut -d'|' -f1)"
      script="$(printf '%s' "$line" | cut -d'|' -f3)"
      printf '  %s["%s"] -->|"executes"| S%s["%s"]\n' \
        "$(graphs_node_id "$pid")" "$pid" "$(graphs_node_id "$script")" "$(basename "$script")"
    done < "$EXPLORE_WORK/pipelines.txt"
    while IFS= read -r gid; do
      [ -n "$gid" ] || continue
      printf '  G%s["%s"] -->|"verified by"| %s["%s"]\n' \
        "$(graphs_node_id "$gid")" "$gid" "$(graphs_node_id "$gid")" "$gid"
    done < "$EXPLORE_WORK/gates.txt"
  } > "$out"
}

# ── Graf: konfiguracja (config/canonical) ───────────────────
graphs_configuration() {
  local out="$GRAPHS_DIR/configuration.mmd"
  {
    graphs_header
    printf 'graph TD\n'
    printf '  CONFIG["config/canonical/"]\n'
    while IFS= read -r c; do
      [ -n "$c" ] || continue
      printf '  CONFIG --> C%s["%s"]\n' "$(graphs_node_id "$c")" "$(basename "$c")"
    done < "$EXPLORE_WORK/config.txt"
  } > "$out"
}

# ── Graf: zależności (pipeline → skrypt) ────────────────────
graphs_dependencies() {
  local out="$GRAPHS_DIR/dependencies.mmd"
  {
    graphs_header
    printf 'graph LR\n'
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      local pid script
      pid="$(printf '%s' "$line" | cut -d'|' -f1)"
      script="$(printf '%s' "$line" | cut -d'|' -f3)"
      if [ -n "$script" ]; then
        printf '  %s["%s"] -->|"uses"| S%s["%s"]\n' \
          "$(graphs_node_id "$pid")" "$pid" "$(graphs_node_id "$script")" "$(basename "$script")"
      fi
    done < "$EXPLORE_WORK/pipelines.txt"
  } > "$out"
}

# ── Graf: evidence (gate → evidence plik) ───────────────────
graphs_evidence() {
  local out="$GRAPHS_DIR/evidence.mmd"
  {
    graphs_header
    printf 'graph LR\n'
    while IFS= read -r ev; do
      [ -n "$ev" ] || continue
      local gid
      gid="$(printf '%s' "$ev" | sed 's/\.evidence$//')"
      printf '  %s["%s"] -->|"evidence"| E%s["%s"]\n' \
        "$(graphs_node_id "$gid")" "$gid" "$(graphs_node_id "$ev")" "$ev"
    done < "$EXPLORE_WORK/evidence.txt"
  } > "$out"
}

# ── Graf: temporal (oś czasu commitów) ──────────────────────
graphs_temporal() {
  local out="$GRAPHS_DIR/temporal.mmd"
  {
    graphs_header
    printf 'graph LR\n'
    printf '  HEAD["HEAD: %s"]\n' "$(git_head)"
    printf '  HEAD -->|"branch"| BR["%s"]\n' "$(git_branch)"
    printf '  BR -->|"dirty"| DIRTY["%s plików"]\n' "$(git_dirty_count)"
  } > "$out"
}

# ── Graf: tasks (pipeline'y jako zadania) ───────────────────
graphs_tasks() {
  local out="$GRAPHS_DIR/tasks.mmd"
  {
    graphs_header
    printf 'graph TD\n'
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      local pid family status
      pid="$(printf '%s' "$line" | cut -d'|' -f1)"
      family="$(printf '%s' "$line" | cut -d'|' -f2)"
      status="$(printf '%s' "$line" | cut -d'|' -f5)"
      printf '  %s["%s (%s)"]\n' "$(graphs_node_id "$pid")" "$pid" "$status"
    done < "$EXPLORE_WORK/pipelines.txt"
  } > "$out"
}

# ── Graf: findings (ghosts, mocks, drift) ───────────────────
graphs_findings() {
  local out="$GRAPHS_DIR/findings.mmd"
  {
    graphs_header
    printf 'graph TD\n'
    local n
    n="$(grep -c '"type":' "$MODEL_JSON" 2>/dev/null || echo 0)"
    if [ "$n" -eq 0 ]; then
      printf '  CLEAN["Brak findings — brak ghost/mock/drift"]\n'
    else
      grep '"type":' "$MODEL_JSON" | sed 's/^    //' | while IFS= read -r line; do
        local type id
        type="$(printf '%s' "$line" | sed -E 's/.*"type": "([^"]*)".*/\1/')"
        id="$(printf '%s' "$line" | sed -E 's/.*"id": "([^"]*)".*/\1/')"
        printf '  %s["%s: %s"]\n' "$(graphs_node_id "$type-$id")" "$type" "$id"
      done
    fi
  } > "$out"
}

# ── Graf: source-of-truth (kanoniczny model) ────────────────
graphs_source_of_truth() {
  local out="$GRAPHS_DIR/source-of-truth.mmd"
  {
    graphs_header
    printf 'graph TD\n'
    printf '  REPO["REPOSITORY"] -->|"discovery"| DISCOVERY["DISCOVERY ENGINE"]\n'
    printf '  DISCOVERY -->|"normalize"| MODEL["CANONICAL MODEL\\nproject-model.json"]\n'
    printf '  MODEL -->|"generate"| DOCS["Markdown indexes"]\n'
    printf '  MODEL -->|"generate"| GRAPHS["Mermaid graphs"]\n'
    printf '  MODEL -->|"generate"| HTML["HTML Explorer"]\n'
    printf '  MODEL -->|"generate"| JSON["summary.json"]\n'
  } > "$out"
}

# ── Graf: full-system (wszystko w jednym) ───────────────────
graphs_full_system() {
  local out="$GRAPHS_DIR/full-system.mmd"
  {
    graphs_header
    printf 'graph TD\n'
    printf '  REPO["REPOSITORY"] -->|"discovery"| DISCOVERY["DISCOVERY ENGINE"]\n'
    printf '  DISCOVERY -->|"normalize"| MODEL["CANONICAL MODEL"]\n'
    printf '  MODEL -->|"generate"| DOCS["Markdown"]\n'
    printf '  MODEL -->|"generate"| GRAPHS["Mermaid"]\n'
    printf '  MODEL -->|"generate"| HTML["HTML Explorer"]\n'
    printf '  MODEL -->|"generate"| JSON["summary.json"]\n'
    printf '  MODEL -->|"validate"| VALIDATE["VALIDATION"]\n'
    printf '  VALIDATE -->|"self-gate"| GATE["OBS-001..015"]\n'
  } > "$out"
}

# ── Pomocniczy: bezpieczny identyfikator węzła Mermaid ──────
graphs_node_id() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9' '_'
}

# ── README.md dla katalogu grafów ───────────────────────────
graphs_readme() {
  local out="$GRAPHS_DIR/README.md"
  {
    printf '# Grafy Mermaid\n\n'
    printf '> Wygenerowano z kanonicznego modelu projektu (project-model.json).\n'
    printf '> Deterministic — nie edytuj ręcznie.\n\n'
    printf '## Katalog grafów\n\n'
    printf '| Graf | Opis |\n'
    printf '|---|---|\n'
    printf '| architecture.mmd | Komponenty i struktura katalogów |\n'
    printf '| gates.mmd | Gatey i ich evidence |\n'
    printf '| pipelines.mmd | Pipeliney i zależności |\n'
    printf '| documentation.mmd | Drzewo dokumentacji docs/ |\n'
    printf '| traceability.mmd | Traceability pipeline → gate → evidence |\n'
    printf '| configuration.mmd | Konfiguracja canonical |\n'
    printf '| dependencies.mmd | Zależności pipeline → skrypt |\n'
    printf '| evidence.mmd | Evidence i ich gatey |\n'
    printf '| temporal.mmd | Stan temporalny (HEAD, branch, dirty) |\n'
    printf '| tasks.mmd | Pipeliney jako zadania |\n'
    printf '| findings.mmd | Ghosts, mocks, drift |\n'
    printf '| source-of-truth.mmd | Architektura kanonicznego modelu |\n'
    printf '| full-system.mmd | Pełny system (discovery → model → widoki) |\n'
  } > "$out"
}

# ── Główna funkcja grafów ───────────────────────────────────
graphs_generate() {
  mkdir -p "$GRAPHS_DIR"
  graphs_architecture
  graphs_gates
  graphs_pipelines
  graphs_documentation
  graphs_traceability
  graphs_configuration
  graphs_dependencies
  graphs_evidence
  graphs_temporal
  graphs_tasks
  graphs_findings
  graphs_source_of_truth
  graphs_full_system
  graphs_readme
  say "Grafy Mermaid wygenerowane: $GRAPHS_DIR/ ($(ls "$GRAPHS_DIR"/*.mmd 2>/dev/null | wc -l) .mmd)"
}
