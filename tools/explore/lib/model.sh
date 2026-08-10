#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# lib/model.sh — CANONICAL PROJECT MODEL BUILDER
# Normalizuje surowe dane discovery do JEDNEGO kanonicznego
# modelu projektu (project-model.json). Jeden model → wiele widoków.
#
# Model zawiera: components, relationships, documents, gates,
# pipelines, contracts, tests, evidence, configuration, findings,
# temporal state. Relacje: FACT (bezpośrednio wykryte) vs
# INFERRED (wywnioskowane) — nigdy nie mieszane.
#
# Coverage metrics: każda ma FORMULA + INPUT SET + EXCLUSIONS.
# NO FAKE 100%: używaj UNKNOWN gdy nie można policzyć.
# ─────────────────────────────────────────────────────────────
set -u

# ── Ścieżki wyjściowe ───────────────────────────────────────
MODEL_JSON="$OUT_GENERATED/project-model.json"
MODEL_SCHEMA="$OUT_GENERATED/project-model.schema.json"
SUMMARY_JSON="$OUT_GENERATED/summary.json"

# ── JSON escape ─────────────────────────────────────────────
json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r//g'
}

# ── Zbuduj sekcję components ────────────────────────────────
# Komponenty = katalogi top-level + kluczowe podsystemy.
model_components() {
  local dirs
  dirs="$(cat "$EXPLORE_WORK/dirs.txt" 2>/dev/null)"
  local first=1
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    [ "$first" -eq 1 ] || printf ',\n'
    first=0
    printf '    { "id": "%s", "type": "directory", "relation": "FACT" }' "$(json_escape "$d")"
  done <<< "$dirs"
}

# ── Zbuduj sekcję pipelines ─────────────────────────────────
# Format z pipelines.txt: "P-XXX|FAMILY|script|class|status|depends|contract"
model_pipelines() {
  local first=1
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    local pid family script class status depends contract
    pid="$(printf '%s' "$line" | cut -d'|' -f1)"
    family="$(printf '%s' "$line" | cut -d'|' -f2)"
    script="$(printf '%s' "$line" | cut -d'|' -f3)"
    class="$(printf '%s' "$line" | cut -d'|' -f4)"
    status="$(printf '%s' "$line" | cut -d'|' -f5)"
    depends="$(printf '%s' "$line" | cut -d'|' -f6)"
    contract="$(printf '%s' "$line" | cut -d'|' -f7)"
    [ "$first" -eq 1 ] || printf ',\n'
    first=0
    printf '    { "id": "%s", "family": "%s", "script": "%s", "class": "%s", "status": "%s", "depends": "%s", "contract": "%s", "relation": "FACT" }' \
      "$(json_escape "$pid")" "$(json_escape "$family")" "$(json_escape "$script")" \
      "$(json_escape "$class")" "$(json_escape "$status")" "$(json_escape "$depends")" \
      "$(json_escape "$contract")"
  done < "$EXPLORE_WORK/pipelines.txt"
}

# ── Zbuduj sekcję gates ─────────────────────────────────────
model_gates() {
  local first=1
  while IFS= read -r gid; do
    [ -n "$gid" ] || continue
    [ "$first" -eq 1 ] || printf ',\n'
    first=0
    printf '    { "id": "%s", "relation": "FACT" }' "$(json_escape "$gid")"
  done < "$EXPLORE_WORK/gates.txt"
}

# ── Zbuduj sekcję evidence ──────────────────────────────────
model_evidence() {
  local first=1
  while IFS= read -r ev; do
    [ -n "$ev" ] || continue
    [ "$first" -eq 1 ] || printf ',\n'
    first=0
    printf '    { "id": "%s", "relation": "FACT" }' "$(json_escape "$ev")"
  done < "$EXPLORE_WORK/evidence.txt"
}

# ── Zbuduj sekcję documents ─────────────────────────────────
model_documents() {
  local first=1
  while IFS= read -r doc; do
    [ -n "$doc" ] || continue
    [ "$first" -eq 1 ] || printf ',\n'
    first=0
    printf '    { "path": "%s", "relation": "FACT" }' "$(json_escape "$doc")"
  done < "$EXPLORE_WORK/docs.txt"
}

# ── Zbuduj sekcję tests ─────────────────────────────────────
model_tests() {
  local first=1
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    [ "$first" -eq 1 ] || printf ',\n'
    first=0
    printf '    { "path": "%s", "relation": "FACT" }' "$(json_escape "$t")"
  done < "$EXPLORE_WORK/tests.txt"
}

# ── Zbuduj sekcję schemas ──────────────────────────────────
model_schemas() {
  local first=1
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    [ "$first" -eq 1 ] || printf ',\n'
    first=0
    printf '    { "path": "%s", "relation": "FACT" }' "$(json_escape "$s")"
  done < "$EXPLORE_WORK/schemas.txt"
}

# ── Zbuduj sekcję configuration ─────────────────────────────
model_config() {
  local first=1
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$first" -eq 1 ] || printf ',\n'
    first=0
    printf '    { "path": "%s", "relation": "FACT" }' "$(json_escape "$c")"
  done < "$EXPLORE_WORK/config.txt"
}

# ── Zbuduj sekcję findings (ghosts, mocks, drift) ───────────
# Ghost: pipeline zarejestrowany, ale skrypt nie istnieje.
# Mock:  skrypt istnieje, ale nie jest zarejestrowany.
# Drift: rozjazd między deklaracją a rzeczywistością.
model_findings() {
  local first=1
  local ghost mock
  # Ghost pipelines: zarejestrowane w pipelines.txt, ale skrypt nie istnieje.
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    local pid script
    pid="$(printf '%s' "$line" | cut -d'|' -f1)"
    script="$(printf '%s' "$line" | cut -d'|' -f3)"
    if [ -n "$script" ] && [ ! -f "$ROOT/tools/automation/$script" ]; then
      [ "$first" -eq 1 ] || printf ',\n'
      first=0
      printf '    { "type": "ghost", "id": "%s", "detail": "pipeline zarejestrowany, skrypt brakuje: %s", "relation": "FACT" }' \
        "$(json_escape "$pid")" "$(json_escape "$script")"
    fi
  done < "$EXPLORE_WORK/pipelines.txt"
  # Ghost gates: zarejestrowane w gates.txt, ale brak evidence.
  while IFS= read -r gid; do
    [ -n "$gid" ] || continue
    if [ ! -f "$ROOT/artifacts/evidence/gates/$gid.evidence" ]; then
      [ "$first" -eq 1 ] || printf ',\n'
      first=0
      printf '    { "type": "ghost", "id": "%s", "detail": "gate zarejestrowany, brak evidence", "relation": "FACT" }' \
        "$(json_escape "$gid")"
    fi
  done < "$EXPLORE_WORK/gates.txt"
  # Mock: skrypty automation istnieją, ale nie są zarejestrowane.
  while IFS= read -r script; do
    [ -n "$script" ] || continue
    local base
    base="$(basename "$script")"
    if ! grep -q "$base" "$EXPLORE_WORK/pipelines.txt" 2>/dev/null; then
      [ "$first" -eq 1 ] || printf ',\n'
      first=0
      printf '    { "type": "mock", "id": "%s", "detail": "skrypt istnieje, brak rejestracji pipeline", "relation": "FACT" }' \
        "$(json_escape "$script")"
    fi
  done < "$EXPLORE_WORK/automation.txt"
}

# ── Coverage metrics ────────────────────────────────────────
# Każda metryka ma FORMULA + INPUT SET + EXCLUSIONS. NO FAKE 100%.
model_coverage() {
  local total_pipes total_gates total_evidence total_docs total_tests
  total_pipes="$(wc -l < "$EXPLORE_WORK/pipelines.txt" 2>/dev/null || echo 0)"
  total_gates="$(wc -l < "$EXPLORE_WORK/gates.txt" 2>/dev/null || echo 0)"
  total_evidence="$(wc -l < "$EXPLORE_WORK/evidence.txt" 2>/dev/null || echo 0)"
  total_docs="$(wc -l < "$EXPLORE_WORK/docs.txt" 2>/dev/null || echo 0)"
  total_tests="$(wc -l < "$EXPLORE_WORK/tests.txt" 2>/dev/null || echo 0)"

  # Evidence coverage: gates z evidence / wszystkie gates.
  local ev_cov="UNKNOWN"
  if [ "$total_gates" -gt 0 ]; then
    ev_cov="$(awk -v e="$total_evidence" -v g="$total_gates" 'BEGIN { printf "%.1f", (e/g)*100 }')"
  fi

  # Pipeline coverage: pipeline'y z istniejącym skryptem / wszystkie.
  local pipe_cov="UNKNOWN" pipe_ok=0
  if [ "$total_pipes" -gt 0 ]; then
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      local script
      script="$(printf '%s' "$line" | cut -d'|' -f3)"
      if [ -n "$script" ] && [ -f "$ROOT/tools/automation/$script" ]; then
        pipe_ok=$((pipe_ok+1))
      fi
    done < "$EXPLORE_WORK/pipelines.txt"
    pipe_cov="$(awk -v o="$pipe_ok" -v t="$total_pipes" 'BEGIN { printf "%.1f", (o/t)*100 }')"
  fi

  printf '    { "metric": "evidence_coverage", "value": "%s", "formula": "evidence/gates*100", "input_set": "artifacts/evidence/gates + registry gates", "exclusions": "gates bez evidence w repo", "relation": "FACT" },\n' "$ev_cov"
  printf '    { "metric": "pipeline_coverage", "value": "%s", "formula": "pipelines_z_skryptem/pipelines*100", "input_set": "pipelines.txt + tools/automation", "exclusions": "pipeliney PROPOSED bez skryptu", "relation": "FACT" },\n' "$pipe_cov"
  printf '    { "metric": "documentation_count", "value": "%s", "formula": "count(docs/**/*.md)", "input_set": "git ls-files docs/**/*.md", "exclusions": "docs/generated (git-ignored)", "relation": "FACT" },\n' "$total_docs"
  printf '    { "metric": "test_count", "value": "%s", "formula": "count(tools/**/tests/*.sh)", "input_set": "git ls-files tools/**/tests/*.sh", "exclusions": "testy runtime (git-ignored)", "relation": "FACT" }' "$total_tests"
}

# ── Zbuduj schema modelu (project-model.schema.json) ────────
# JSON Schema opisujący kanoniczny model. Deterministic.
model_schema() {
  {
    printf '{\n'
    printf '  "$schema": "http://json-schema.org/draft-07/schema#",\n'
    printf '  "title": "Prod-ready Canonical Project Model",\n'
    printf '  "type": "object",\n'
    printf '  "required": ["schema_version", "generated_at", "generator", "git", "components", "pipelines", "gates", "evidence", "documents", "tests", "schemas", "configuration", "findings", "coverage"],\n'
    printf '  "properties": {\n'
    printf '    "schema_version": { "type": "integer" },\n'
    printf '    "generated_at": { "type": "string" },\n'
    printf '    "generator": { "type": "string" },\n'
    printf '    "git": { "type": "object" },\n'
    printf '    "components": { "type": "array" },\n'
    printf '    "pipelines": { "type": "array" },\n'
    printf '    "gates": { "type": "array" },\n'
    printf '    "evidence": { "type": "array" },\n'
    printf '    "documents": { "type": "array" },\n'
    printf '    "tests": { "type": "array" },\n'
    printf '    "schemas": { "type": "array" },\n'
    printf '    "configuration": { "type": "array" },\n'
    printf '    "findings": { "type": "array" },\n'
    printf '    "coverage": { "type": "array" }\n'
    printf '  }\n'
    printf '}\n'
  } > "$MODEL_SCHEMA"
}

# ── Zbuduj pełny model ──────────────────────────────────────
model_build() {
  mkdir -p "$OUT_GENERATED" "$OUT_INDEXES"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  {
    printf '{\n'
    printf '  "schema_version": 1,\n'
    printf '  "generated_at": "%s",\n' "$ts"
    printf '  "generator": "tools/explore/explore.sh",\n'
    printf '  "git": {\n'
    printf '    "head": "%s",\n' "$(json_escape "$(git_head)")"
    printf '    "branch": "%s",\n' "$(json_escape "$(git_branch)")"
    printf '    "dirty": %s,\n' "$(git_dirty_count)"
    printf '    "uncommitted": %s\n' "$(git_uncommitted_count)"
    printf '  },\n'
    printf '  "components": [\n'
    model_components
    printf '\n  ],\n'
    printf '  "pipelines": [\n'
    model_pipelines
    printf '\n  ],\n'
    printf '  "gates": [\n'
    model_gates
    printf '\n  ],\n'
    printf '  "evidence": [\n'
    model_evidence
    printf '\n  ],\n'
    printf '  "documents": [\n'
    model_documents
    printf '\n  ],\n'
    printf '  "tests": [\n'
    model_tests
    printf '\n  ],\n'
    printf '  "schemas": [\n'
    model_schemas
    printf '\n  ],\n'
    printf '  "configuration": [\n'
    model_config
    printf '\n  ],\n'
    printf '  "findings": [\n'
    model_findings
    printf '\n  ],\n'
    printf '  "coverage": [\n'
    model_coverage
    printf '\n  ]\n'
    printf '}\n'
  } > "$MODEL_JSON"

  # Redakcja sekretów w modelu.
  redact_file "$MODEL_JSON"

  # Zbuduj schema modelu.
  model_schema

  # Zbuduj summary.json.
  model_summary
  say "Model zbudowany: $MODEL_JSON"
}

# ── Zbuduj summary.json ─────────────────────────────────────
model_summary() {
  local total_pipes total_gates total_evidence total_docs total_tests total_findings
  total_pipes="$(wc -l < "$EXPLORE_WORK/pipelines.txt" 2>/dev/null || echo 0)"
  total_gates="$(wc -l < "$EXPLORE_WORK/gates.txt" 2>/dev/null || echo 0)"
  total_evidence="$(wc -l < "$EXPLORE_WORK/evidence.txt" 2>/dev/null || echo 0)"
  total_docs="$(wc -l < "$EXPLORE_WORK/docs.txt" 2>/dev/null || echo 0)"
  total_tests="$(wc -l < "$EXPLORE_WORK/tests.txt" 2>/dev/null || echo 0)"
  total_findings="$(grep -c '"type":' "$MODEL_JSON" 2>/dev/null || echo 0)"

  {
    printf '{\n'
    printf '  "generated_at": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '  "git_head": "%s",\n' "$(json_escape "$(git_head)")"
    printf '  "git_branch": "%s",\n' "$(json_escape "$(git_branch)")"
    printf '  "git_dirty": %s,\n' "$(git_dirty_count)"
    printf '  "counts": {\n'
    printf '    "pipelines": %s,\n' "$total_pipes"
    printf '    "gates": %s,\n' "$total_gates"
    printf '    "evidence": %s,\n' "$total_evidence"
    printf '    "documents": %s,\n' "$total_docs"
    printf '    "tests": %s,\n' "$total_tests"
    printf '    "findings": %s\n' "$total_findings"
    printf '  }\n'
    printf '}\n'
  } > "$SUMMARY_JSON"
  redact_file "$SUMMARY_JSON"
}

# ── Status (podsumowanie dla CLI) ───────────────────────────
model_status() {
  say ""
  say "=== STATUS PROJEKTU ==="
  say "HEAD:      $(git_head) ($(git_branch))"
  say "Dirty:     $(git_dirty_count) plików"
  say "Pipeline'y: $(wc -l < "$EXPLORE_WORK/pipelines.txt" 2>/dev/null || echo 0)"
  say "Gate'y:    $(wc -l < "$EXPLORE_WORK/gates.txt" 2>/dev/null || echo 0)"
  say "Evidence:  $(wc -l < "$EXPLORE_WORK/evidence.txt" 2>/dev/null || echo 0)"
  say "Dokumenty: $(wc -l < "$EXPLORE_WORK/docs.txt" 2>/dev/null || echo 0)"
  say "Testy:     $(wc -l < "$EXPLORE_WORK/tests.txt" 2>/dev/null || echo 0)"
  say "Findings:  $(grep -c '"type":' "$MODEL_JSON" 2>/dev/null || echo 0)"
  say ""
  say "Coverage:"
  grep '"metric"' "$MODEL_JSON" 2>/dev/null | sed 's/^    //'
}
