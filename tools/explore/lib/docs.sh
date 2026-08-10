#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# lib/docs.sh — MARKDOWN INDEX GENERATOR
# Generuje docs/index.md (główny indeks projektu) oraz indeksy
# w docs/generated/indexes/ (components, pipelines, gates,
# evidence, documents, tests, schemas, configuration, findings).
#
# Wszystkie indeksy są generowane z kanonicznego modelu
# (project-model.json) — JEDEN model → wiele widoków.
# ─────────────────────────────────────────────────────────────
set -u

# ── Generuj indeks komponentów ──────────────────────────────
docs_components_index() {
  local out="$OUT_INDEXES/components.md"
  {
    printf '# Komponenty\n\n'
    printf '> Wygenerowano z kanonicznego modelu projektu.\n\n'
    printf '| Komponent | Typ | Relacja |\n'
    printf '|---|---|---|\n'
    grep '"id":' "$MODEL_JSON" | sed 's/^    //' | while IFS= read -r line; do
      local id type rel
      id="$(printf '%s' "$line" | sed -E 's/.*"id": "([^"]*)".*/\1/')"
      type="$(printf '%s' "$line" | sed -E 's/.*"type": "([^"]*)".*/\1/')"
      rel="$(printf '%s' "$line" | sed -E 's/.*"relation": "([^"]*)".*/\1/')"
      printf '| %s | %s | %s |\n' "$id" "$type" "$rel"
    done
  } > "$out"
}

# ── Generuj indeks pipeline'ów ──────────────────────────────
docs_pipelines_index() {
  local out="$OUT_INDEXES/pipelines.md"
  {
    printf '# Pipeliney\n\n'
    printf '> Wygenerowano z kanonicznego modelu projektu.\n\n'
    printf '| ID | Rodzina | Skrypt | Klasa | Status | Zależności |\n'
    printf '|---|---|---|---|---|---|\n'
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      local pid family script class status depends
      pid="$(printf '%s' "$line" | cut -d'|' -f1)"
      family="$(printf '%s' "$line" | cut -d'|' -f2)"
      script="$(printf '%s' "$line" | cut -d'|' -f3)"
      class="$(printf '%s' "$line" | cut -d'|' -f4)"
      status="$(printf '%s' "$line" | cut -d'|' -f5)"
      depends="$(printf '%s' "$line" | cut -d'|' -f6)"
      printf '| %s | %s | %s | %s | %s | %s |\n' "$pid" "$family" "$script" "$class" "$status" "$depends"
    done < "$EXPLORE_WORK/pipelines.txt"
  } > "$out"
}

# ── Generuj indeks gate'ów ──────────────────────────────────
docs_gates_index() {
  local out="$OUT_INDEXES/gates.md"
  {
    printf '# Gatey\n\n'
    printf '> Wygenerowano z kanonicznego modelu projektu.\n\n'
    printf '| Gate | Evidence |\n'
    printf '|---|---|\n'
    while IFS= read -r gid; do
      [ -n "$gid" ] || continue
      local ev="BRAK"
      [ -f "$ROOT/artifacts/evidence/gates/$gid.evidence" ] && ev="TAK"
      printf '| %s | %s |\n' "$gid" "$ev"
    done < "$EXPLORE_WORK/gates.txt"
  } > "$out"
}

# ── Generuj indeks dokumentów ───────────────────────────────
docs_documents_index() {
  local out="$OUT_INDEXES/documents.md"
  {
    printf '# Dokumentacja\n\n'
    printf '> Wygenerowano z kanonicznego modelu projektu.\n\n'
    while IFS= read -r doc; do
      [ -n "$doc" ] || continue
      printf -- '- %s\n' "$doc"
    done < "$EXPLORE_WORK/docs.txt"
  } > "$out"
}

# ── Generuj indeks findings ─────────────────────────────────
docs_findings_index() {
  local out="$OUT_INDEXES/findings.md"
  {
    printf '# Findings (ghosts, mocks, drift)\n\n'
    printf '> Wygenerowano z kanonicznego modelu projektu.\n\n'
    local n
    n="$(grep -c '"type":' "$MODEL_JSON" 2>/dev/null || echo 0)"
    if [ "$n" -eq 0 ]; then
      printf 'Brak findings — brak ghost/mock/drift wykrytych.\n'
    else
      grep '"type":' "$MODEL_JSON" | sed 's/^    //' | while IFS= read -r line; do
        local type id detail
        type="$(printf '%s' "$line" | sed -E 's/.*"type": "([^"]*)".*/\1/')"
        id="$(printf '%s' "$line" | sed -E 's/.*"id": "([^"]*)".*/\1/')"
        detail="$(printf '%s' "$line" | sed -E 's/.*"detail": "([^"]*)".*/\1/')"
        printf -- '- **%s** `%s`: %s\n' "$type" "$id" "$detail"
      done
    fi
  } > "$out"
}

# ── Generuj główny indeks docs/index.md ─────────────────────
docs_main_index() {
  local out="$OUT_DOCS/index.md"
  local total_pipes total_gates total_evidence total_docs total_tests
  total_pipes="$(wc -l < "$EXPLORE_WORK/pipelines.txt" 2>/dev/null || echo 0)"
  total_gates="$(wc -l < "$EXPLORE_WORK/gates.txt" 2>/dev/null || echo 0)"
  total_evidence="$(wc -l < "$EXPLORE_WORK/evidence.txt" 2>/dev/null || echo 0)"
  total_docs="$(wc -l < "$EXPLORE_WORK/docs.txt" 2>/dev/null || echo 0)"
  total_tests="$(wc -l < "$EXPLORE_WORK/tests.txt" 2>/dev/null || echo 0)"

  {
    printf '# Prod-ready — Indeks Projektu\n\n'
    printf '> Wygenerowano automatycznie przez **PROD-READY OBSERVABILITY & KNOWLEDGE EXPLORER**.\n'
    printf '> Jedno źródło prawdy: `docs/generated/project-model.json`.\n\n'
    printf '## Stan\n\n'
    printf '| Metryka | Wartość |\n'
    printf '|---|---|\n'
    printf '| HEAD | `%s` |\n' "$(git_head)"
    printf '| Branch | `%s` |\n' "$(git_branch)"
    printf '| Dirty | %s plików |\n' "$(git_dirty_count)"
    printf '| Pipeliney | %s |\n' "$total_pipes"
    printf '| Gatey | %s |\n' "$total_gates"
    printf '| Evidence | %s |\n' "$total_evidence"
    printf '| Dokumenty | %s |\n' "$total_docs"
    printf '| Testy | %s |\n' "$total_tests"
    printf '\n'
    printf '## Widoki\n\n'
    printf '| Widok | Ścieżka |\n'
    printf '|---|---|\n'
    printf '| Kanoniczny model | `docs/generated/project-model.json` |\n'
    printf '| Schema | `docs/generated/project-model.schema.json` |\n'
    printf '| Podsumowanie | `docs/generated/summary.json` |\n'
    printf '| HTML Explorer | `docs/explorer/index.html` |\n'
    printf '| Grafy Mermaid | `docs/graphs/README.md` |\n'
    printf '| Indeksy | `docs/generated/indexes/` |\n'
    printf '\n'
    printf '## Indeksy\n\n'
    printf -- '- [Komponenty](generated/indexes/components.md)\n'
    printf -- '- [Pipeliney](generated/indexes/pipelines.md)\n'
    printf -- '- [Gatey](generated/indexes/gates.md)\n'
    printf -- '- [Dokumentacja](generated/indexes/documents.md)\n'
    printf -- '- [Findings](generated/indexes/findings.md)\n'
    printf '\n'
    printf '## Raport\n\n'
    printf -- '- [Raport obserwowalności](audit/OBSERVABILITY-EXPLORER-REPORT.md)\n'
  } > "$out"
}

# ── Główna funkcja docs ─────────────────────────────────────
docs_generate() {
  mkdir -p "$OUT_INDEXES"
  docs_components_index
  docs_pipelines_index
  docs_gates_index
  docs_documents_index
  docs_findings_index
  docs_main_index
  say "Indeksy Markdown wygenerowane: $OUT_DOCS/index.md + $OUT_INDEXES/"
}
