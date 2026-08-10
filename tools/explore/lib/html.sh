#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# lib/html.sh — STATIC HTML EXPLORER GENERATOR
# Generuje docs/explorer/index.html + assets/ + data/ z
# kanonicznego modelu projektu (project-model.json).
# JEDEN model → wiele widoków.
#
# Offline: zero zewnętrznych zależności (inline CSS/JS).
# Deterministic: generowane z posortowanych danych.
# ─────────────────────────────────────────────────────────────
set -u

# ── Katalog wyjściowy HTML ──────────────────────────────────
EXPLORER_DIR="$OUT_EXPLORER"

# ── Kopiuj dane modelu do data/ ─────────────────────────────
html_data() {
  mkdir -p "$EXPLORER_DIR/data"
  cp "$MODEL_JSON" "$EXPLORER_DIR/data/project-model.json"
  cp "$SUMMARY_JSON" "$EXPLORER_DIR/data/summary.json"
  cp "$MODEL_SCHEMA" "$EXPLORER_DIR/data/project-model.schema.json"
}

# ── Generuj index.html ──────────────────────────────────────
html_index() {
  local out="$EXPLORER_DIR/index.html"
  local total_pipes total_gates total_evidence total_docs total_tests total_findings
  total_pipes="$(wc -l < "$EXPLORE_WORK/pipelines.txt" 2>/dev/null || echo 0)"
  total_gates="$(wc -l < "$EXPLORE_WORK/gates.txt" 2>/dev/null || echo 0)"
  total_evidence="$(wc -l < "$EXPLORE_WORK/evidence.txt" 2>/dev/null || echo 0)"
  total_docs="$(wc -l < "$EXPLORE_WORK/docs.txt" 2>/dev/null || echo 0)"
  total_tests="$(wc -l < "$EXPLORE_WORK/tests.txt" 2>/dev/null || echo 0)"
  total_findings="$(grep -c '"type":' "$MODEL_JSON" 2>/dev/null || echo 0)"

  {
    printf '<!DOCTYPE html>\n'
    printf '<html lang="pl">\n'
    printf '<head>\n'
    printf '  <meta charset="utf-8">\n'
    printf '  <meta name="viewport" content="width=device-width, initial-scale=1">\n'
    printf '  <title>Prod-ready — Observability & Knowledge Explorer</title>\n'
    printf '  <style>\n'
    printf '    body { font-family: system-ui, sans-serif; margin: 2rem; color: #1a1a1a; }\n'
    printf '    h1 { border-bottom: 2px solid #333; padding-bottom: .5rem; }\n'
    printf '    table { border-collapse: collapse; width: 100%%; margin: 1rem 0; }\n'
    printf '    th, td { border: 1px solid #ccc; padding: .4rem .6rem; text-align: left; }\n'
    printf '    th { background: #f0f0f0; }\n'
    printf '    .card { border: 1px solid #ddd; border-radius: 8px; padding: 1rem; margin: 1rem 0; }\n'
    printf '    .metric { font-size: 2rem; font-weight: bold; }\n'
    printf '    code { background: #f5f5f5; padding: .1rem .3rem; border-radius: 3px; }\n'
    printf '  </style>\n'
    printf '</head>\n'
    printf '<body>\n'
    printf '  <h1>Prod-ready — Observability &amp; Knowledge Explorer</h1>\n'
    printf '  <p>Wygenerowano z kanonicznego modelu projektu. Jedno źródło prawdy: <code>docs/generated/project-model.json</code>.</p>\n'
    printf '  <div class="card"><h2>Stan</h2>\n'
    printf '    <table>\n'
    printf '      <tr><th>HEAD</th><td><code>%s</code></td></tr>\n' "$(git_head)"
    printf '      <tr><th>Branch</th><td><code>%s</code></td></tr>\n' "$(git_branch)"
    printf '      <tr><th>Dirty</th><td>%s plików</td></tr>\n' "$(git_dirty_count)"
    printf '    </table>\n'
    printf '  </div>\n'
    printf '  <div class="card"><h2>Metryki</h2>\n'
    printf '    <table>\n'
    printf '      <tr><th>Pipeliney</th><td class="metric">%s</td></tr>\n' "$total_pipes"
    printf '      <tr><th>Gatey</th><td class="metric">%s</td></tr>\n' "$total_gates"
    printf '      <tr><th>Evidence</th><td class="metric">%s</td></tr>\n' "$total_evidence"
    printf '      <tr><th>Dokumenty</th><td class="metric">%s</td></tr>\n' "$total_docs"
    printf '      <tr><th>Testy</th><td class="metric">%s</td></tr>\n' "$total_tests"
    printf '      <tr><th>Findings</th><td class="metric">%s</td></tr>\n' "$total_findings"
    printf '    </table>\n'
    printf '  </div>\n'
    printf '  <div class="card"><h2>Pipeliney</h2>\n'
    printf '    <table>\n'
    printf '      <tr><th>ID</th><th>Rodzina</th><th>Skrypt</th><th>Status</th></tr>\n'
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      local pid family script status
      pid="$(printf '%s' "$line" | cut -d'|' -f1)"
      family="$(printf '%s' "$line" | cut -d'|' -f2)"
      script="$(printf '%s' "$line" | cut -d'|' -f3)"
      status="$(printf '%s' "$line" | cut -d'|' -f5)"
      printf '      <tr><td><code>%s</code></td><td>%s</td><td><code>%s</code></td><td>%s</td></tr>\n' \
        "$pid" "$family" "$script" "$status"
    done < "$EXPLORE_WORK/pipelines.txt"
    printf '    </table>\n'
    printf '  </div>\n'
    printf '  <div class="card"><h2>Gatey</h2>\n'
    printf '    <table>\n'
    printf '      <tr><th>Gate</th><th>Evidence</th></tr>\n'
    while IFS= read -r gid; do
      [ -n "$gid" ] || continue
      local ev="BRAK"
      [ -f "$ROOT/artifacts/evidence/gates/$gid.evidence" ] && ev="TAK"
      printf '      <tr><td><code>%s</code></td><td>%s</td></tr>\n' "$gid" "$ev"
    done < "$EXPLORE_WORK/gates.txt"
    printf '    </table>\n'
    printf '  </div>\n'
    printf '  <div class="card"><h2>Findings</h2>\n'
    if [ "$total_findings" -eq 0 ]; then
      printf '    <p>Brak findings — brak ghost/mock/drift wykrytych.</p>\n'
    else
      printf '    <ul>\n'
      grep '"type":' "$MODEL_JSON" | sed 's/^    //' | while IFS= read -r line; do
        local type id
        type="$(printf '%s' "$line" | sed -E 's/.*"type": "([^"]*)".*/\1/')"
        id="$(printf '%s' "$line" | sed -E 's/.*"id": "([^"]*)".*/\1/')"
        printf '      <li><strong>%s</strong> <code>%s</code></li>\n' "$type" "$id"
      done
      printf '    </ul>\n'
    fi
    printf '  </div>\n'
    printf '  <div class="card"><h2>Dane</h2>\n'
    printf '    <ul>\n'
    printf '      <li><a href="data/project-model.json">project-model.json</a></li>\n'
    printf '      <li><a href="data/summary.json">summary.json</a></li>\n'
    printf '      <li><a href="data/project-model.schema.json">project-model.schema.json</a></li>\n'
    printf '    </ul>\n'
    printf '  </div>\n'
    printf '  <p><em>Wygenerowano automatycznie — nie edytuj ręcznie.</em></p>\n'
    printf '</body>\n'
    printf '</html>\n'
  } > "$out"
}

# ── Główna funkcja HTML ─────────────────────────────────────
html_generate() {
  mkdir -p "$EXPLORER_DIR" "$EXPLORER_DIR/assets" "$EXPLORER_DIR/data"
  html_data
  html_index
  say "HTML Explorer wygenerowany: $EXPLORER_DIR/index.html"
}
