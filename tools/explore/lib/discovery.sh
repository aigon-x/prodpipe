#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# lib/discovery.sh — DISCOVERY ENGINE
# Zbiera surowe dane z repo (filesystem, git, config, contracts,
# gates, pipelines, tests, docs, schemas, evidence, StateStore)
# i zapisuje je do katalogu roboczego (docs/generated/.explore/).
#
# Discovery jest FAZA 1 kanonicznego modelu: REPOSITORY → DISCOVERY.
# Dane surowe są później normalizowane przez model.sh do JEDNEGO
# kanonicznego modelu projektu (project-model.json).
#
# Deterministic: kolejność wyjścia jest stabilna (sortowane listy).
# Secret redaction: żadne sekrety nie trafiają do danych surowych.
# ─────────────────────────────────────────────────────────────
set -u

# ── Katalog roboczy discovery ───────────────────────────────
EXPLORE_WORK="$ROOT/docs/generated/.explore"

# ── Inicjalizacja katalogu roboczego ────────────────────────
discovery_init() {
  rm -rf "$EXPLORE_WORK"
  mkdir -p "$EXPLORE_WORK"
}

# ── Zbierz listę plików śledzonych przez git ────────────────
discovery_files() {
  git ls-files 2>/dev/null | sort > "$EXPLORE_WORK/files.txt"
}

# ── Zbierz strukturę katalogów (top-level + docs) ───────────
discovery_dirs() {
  {
    git ls-files 2>/dev/null | cut -d/ -f1 | sort -u
    git ls-files 'docs/**' 2>/dev/null | cut -d/ -f2 | sort -u
  } | sort -u > "$EXPLORE_WORK/dirs.txt"
}

# ── Zbierz stan git (HEAD, status, drift) ───────────────────
discovery_git() {
  {
    echo "head=$(git rev-parse HEAD 2>/dev/null)"
    echo "branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    echo "dirty=$(git status --porcelain 2>/dev/null | wc -l)"
    echo "uncommitted=$(git status --porcelain 2>/dev/null | grep -c '^ M\|^??' || true)"
  } > "$EXPLORE_WORK/git.txt"
}

# ── Zbierz pipeline'y z pipelines.sh (kanoniczny katalog) ──
discovery_pipelines() {
  local f="$ROOT/tools/automation/core/pipelines.sh"
  if [ -f "$f" ]; then
    # Wyciągnij linie PIPELINES=( ... ) — format: "P-XXX|FAMILY|script|class|status|depends|contract"
    sed -n '/^PIPELINES=(/,/^)/p' "$f" \
      | grep -oE '"[A-Z0-9-]+\|[A-Z-]+\|[^"]*"' \
      | tr -d '"' | sort > "$EXPLORE_WORK/pipelines.txt"
  else
    : > "$EXPLORE_WORK/pipelines.txt"
  fi
}

# ── Zbierz gate'y z registry.sh (kanoniczny katalog) ────────
discovery_gates() {
  local f="$ROOT/tools/verify/gates/registry.sh"
  if [ -f "$f" ]; then
    # Wyciągnij gate_id (pierwsze pole każdego wpisu GATE_REGISTRY).
    sed -n '/^GATE_REGISTRY=(/,/^)/p' "$f" \
      | grep -oE "'GATE-[0-9]+'" \
      | tr -d "'" | sort -u > "$EXPLORE_WORK/gates.txt"
  else
    : > "$EXPLORE_WORK/gates.txt"
  fi
}

# ── Zbierz evidence z artifacts/evidence/gates/ ─────────────
discovery_evidence() {
  local dir="$ROOT/artifacts/evidence/gates"
  if [ -d "$dir" ]; then
    ls "$dir" 2>/dev/null | grep -E '^GATE-[0-9]+\.evidence$' | sort > "$EXPLORE_WORK/evidence.txt"
  else
    : > "$EXPLORE_WORK/evidence.txt"
  fi
}

# ── Zbierz dokumentację (docs/**/*.md) ──────────────────────
discovery_docs() {
  git ls-files 'docs/**/*.md' 2>/dev/null | sort > "$EXPLORE_WORK/docs.txt"
  git ls-files '*.md' 2>/dev/null | sort > "$EXPLORE_WORK/root-docs.txt"
}

# ── Zbierz testy (tools/**/tests/*.sh) ──────────────────────
discovery_tests() {
  git ls-files 'tools/**/tests/*.sh' 2>/dev/null | sort > "$EXPLORE_WORK/tests.txt"
}

# ── Zbierz schematy (config/canonical/*.yaml) ───────────────
discovery_schemas() {
  git ls-files 'config/canonical/*.yaml' 2>/dev/null | sort > "$EXPLORE_WORK/schemas.txt"
}

# ── Zbierz skrypty automation (tools/automation/**/*.sh) ────
discovery_automation() {
  git ls-files 'tools/automation/**/*.sh' 2>/dev/null | sort > "$EXPLORE_WORK/automation.txt"
}

# ── Zbierz skrypty verify (tools/verify/**/*.sh) ────────────
discovery_verify() {
  git ls-files 'tools/verify/**/*.sh' 2>/dev/null | sort > "$EXPLORE_WORK/verify.txt"
}

# ── Zbierz skrypty explore (tools/explore/**/*.sh) ──────────
discovery_explore() {
  git ls-files 'tools/explore/**/*.sh' 2>/dev/null | sort > "$EXPLORE_WORK/explore.txt"
}

# ── Zbierz konfigurację canonical (config/canonical/) ───────
discovery_config() {
  git ls-files 'config/canonical/*' 2>/dev/null | sort > "$EXPLORE_WORK/config.txt"
}

# ── Zbierz kontrakty (README.md z 12 sekcjami) ──────────────
discovery_contracts() {
  # README.md poza root — każdy musi mieć 12 sekcji kontraktu.
  git ls-files '*/README.md' 2>/dev/null | sort > "$EXPLORE_WORK/readmes.txt"
}

# ── Zbierz stan StateStore (jeśli dostępny) ─────────────────
discovery_statestore() {
  local db="$ROOT/system/control-plane/state/data/canonical-state.db"
  if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
    {
      echo "schema_version=$(sqlite3 "$db" 'SELECT schema_version FROM schema_version ORDER BY id DESC LIMIT 1;' 2>/dev/null)"
      echo "evidence_count=$(sqlite3 "$db" 'SELECT COUNT(*) FROM evidence;' 2>/dev/null)"
      echo "pipeline_runs=$(sqlite3 "$db" 'SELECT COUNT(*) FROM pipeline_runs;' 2>/dev/null)"
    } > "$EXPLORE_WORK/statestore.txt"
  else
    : > "$EXPLORE_WORK/statestore.txt"
  fi
}

# ── Główna funkcja discovery ────────────────────────────────
discovery_run() {
  discovery_init
  discovery_files
  discovery_dirs
  discovery_git
  discovery_pipelines
  discovery_gates
  discovery_evidence
  discovery_docs
  discovery_tests
  discovery_schemas
  discovery_automation
  discovery_verify
  discovery_explore
  discovery_config
  discovery_contracts
  discovery_statestore
  say "Discovery zakończone: $(find "$EXPLORE_WORK" -type f | wc -l) plików danych surowych."
}
