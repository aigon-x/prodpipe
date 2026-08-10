#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# explore.sh — PROD-READY OBSERVABILITY & KNOWLEDGE EXPLORER
# Lokalne "centrum dowodzenia" projektu Prod-ready.
#
# ARCHITEKTURA: Explorer oparty na JEDNYM kanonicznym modelu projektu.
#   REPOSITORY → DISCOVERY ENGINE → NORMALIZED PROJECT MODEL → GENERATORS
#   (Markdown, Mermaid, JSON, HTML, indexes)
#
# Jeden model → wiele widoków. Jedno źródło prawdy.
#
# Komendy:
#   help     — pomoc
#   scan     — discovery: zbierz surowe dane z repo (fs, git, config, contracts,
#              gates, pipelines, tests, docs, schemas, evidence, StateStore)
#   build    — zbuduj kanoniczny model projektu (normalized JSON)
#   docs     — wygeneruj indeksy Markdown (docs/index.md, docs/generated/indexes/)
#   graphs   — wygeneruj katalog grafów Mermaid (docs/graphs/)
#   html     — wygeneruj statyczny HTML explorer (docs/explorer/)
#   all      — GŁÓWNA KOMENDA: scan+build+docs+graphs+html+validate+status
#   status   — podsumowanie stanu projektu (metryki, pokrycie, drift)
#   validate — walidacja modelu względem schematu
#   clean    — usuń wygenerowane artefakty
#
# Deterministic generation, offline operation, secret redaction,
# snapshot mechanism, self-gate (OBS-001..015), negative tests.
# ─────────────────────────────────────────────────────────────
set -u

# ── Lokalizacja skryptu i root repo ─────────────────────────
EXPLORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$EXPLORE_DIR/../.." && pwd)"
cd "$ROOT"

# ── Katalogi wyjściowe ──────────────────────────────────────
OUT_DOCS="$ROOT/docs"
OUT_GENERATED="$OUT_DOCS/generated"
OUT_INDEXES="$OUT_GENERATED/indexes"
OUT_GRAPHS="$OUT_DOCS/graphs"
OUT_EXPLORER="$OUT_DOCS/explorer"
OUT_AUDIT="$OUT_DOCS/audit"

# ── Kolory (jeśli TTY) ──────────────────────────────────────
if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_CYAN=$'\033[36m'; C_BOLD=$'\033[1m'; C_RESET=$'\033[0m'
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_BOLD=""; C_RESET=""
fi

say()  { printf '%s\n' "$*"; }
sayc() { printf '%s%s%s\n' "$2" "$1" "$C_RESET"; }

# ── Źródło bibliotek ────────────────────────────────────────
# Każda biblioteka jest źródłowana w momencie użycia (lazy), aby
# `explore.sh help` działało bez pełnego środowiska.
lib() { . "$EXPLORE_DIR/lib/$1.sh"; }

# ── Pomoc ───────────────────────────────────────────────────
explore_help() {
  say "PROD-READY OBSERVABILITY & KNOWLEDGE EXPLORER"
  say ""
  say "Użycie: explore.sh <komenda>"
  say ""
  say "Komendy:"
  say "  help     — ta pomoc"
  say "  scan     — discovery: zbierz surowe dane z repo"
  say "  build    — zbuduj kanoniczny model projektu (JSON)"
  say "  docs     — wygeneruj indeksy Markdown"
  say "  graphs   — wygeneruj katalog grafów Mermaid"
  say "  html     — wygeneruj statyczny HTML explorer"
  say "  all      — GŁÓWNA KOMENDA: scan+build+docs+graphs+html+validate+status"
  say "  status   — podsumowanie stanu projektu"
  say "  validate — walidacja modelu względem schematu"
  say "  clean    — usuń wygenerowane artefakty"
  say ""
  say "Wyjścia:"
  say "  docs/index.md                        — główny indeks projektu"
  say "  docs/explorer/index.html             — statyczny HTML explorer"
  say "  docs/generated/project-model.json    — kanoniczny model"
  say "  docs/generated/project-model.schema.json — JSON schema"
  say "  docs/generated/summary.json          — metryki podsumowujące"
  say "  docs/generated/indexes/              — indeksy"
  say "  docs/graphs/*.mmd                    — katalog grafów Mermaid"
  say "  docs/audit/OBSERVABILITY-EXPLORER-REPORT.md — raport końcowy"
}

# ── Komendy ─────────────────────────────────────────────────
explore_scan() {
  sayc "=== EXPLORE: SCAN (discovery) ===" "$C_CYAN"
  lib discovery
  discovery_run
}

explore_build() {
  sayc "=== EXPLORE: BUILD (model) ===" "$C_CYAN"
  lib discovery
  lib model
  lib git
  lib security
  discovery_run
  model_build
}

explore_docs() {
  sayc "=== EXPLORE: DOCS (markdown indexes) ===" "$C_CYAN"
  lib discovery
  lib model
  lib git
  lib docs
  lib security
  discovery_run
  model_build
  docs_generate
}

explore_graphs() {
  sayc "=== EXPLORE: GRAPHS (mermaid) ===" "$C_CYAN"
  lib discovery
  lib model
  lib git
  lib graphs
  lib security
  discovery_run
  model_build
  graphs_generate
}

explore_html() {
  sayc "=== EXPLORE: HTML (static explorer) ===" "$C_CYAN"
  lib discovery
  lib model
  lib git
  lib html
  lib security
  discovery_run
  model_build
  html_generate
}

explore_validate() {
  sayc "=== EXPLORE: VALIDATE (model vs schema) ===" "$C_CYAN"
  lib model
  lib security
  lib validate
  validate_run
}

explore_status() {
  sayc "=== EXPLORE: STATUS ===" "$C_CYAN"
  lib discovery
  lib model
  lib git
  lib security
  discovery_run
  model_build
  model_status
}

explore_clean() {
  sayc "=== EXPLORE: CLEAN ===" "$C_YELLOW"
  rm -rf "$OUT_INDEXES"
  rm -rf "$OUT_GRAPHS"
  rm -rf "$OUT_EXPLORER"
  rm -f "$OUT_GENERATED/project-model.json"
  rm -f "$OUT_GENERATED/project-model.schema.json"
  rm -f "$OUT_GENERATED/summary.json"
  rm -f "$OUT_DOCS/index.md"
  rm -f "$OUT_AUDIT/OBSERVABILITY-EXPLORER-REPORT.md"
  say "Usunięto wygenerowane artefakty."
}

# ── GŁÓWNA KOMENDA: all ─────────────────────────────────────
# Jedna komenda reprodukuje CAŁY obraz projektu.
explore_all() {
  sayc "=== EXPLORE: ALL (pełny obraz projektu) ===" "$C_BOLD"
  explore_scan
  explore_build
  explore_docs
  explore_graphs
  explore_html
  explore_validate
  explore_status
  sayc "=== EXPLORE: ALL ZAKOŃCZONE ===" "$C_GREEN"
}

# ── Dispatch ────────────────────────────────────────────────
CMD="${1:-help}"
case "$CMD" in
  help|-h|--help)  explore_help ;;
  scan)            explore_scan ;;
  build)           explore_build ;;
  docs)            explore_docs ;;
  graphs)          explore_graphs ;;
  html)            explore_html ;;
  all)             explore_all ;;
  status)          explore_status ;;
  validate)        explore_validate ;;
  clean)           explore_clean ;;
  *)
    sayc "Nieznana komenda: $CMD" "$C_RED"
    explore_help
    exit 2
    ;;
esac
