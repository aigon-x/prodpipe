#!/usr/bin/env bash
# ============================================================================
# discovery.sh — TESTFORGE test discovery
# ============================================================================
# Skanuje repo i znajduje testy. Test = plik *.test.sh w tests/ (lub
# dowolnym katalogu), który jest wykonywalny i kończy się tf_exit.
#
# Konwencja nazewnictwa:
#   tests/<kategoria>/<nazwa>.test.sh
#   np. tests/unit/state.test.sh, tests/contract/verify.test.sh
#
# Discovery zwraca listę ścieżek (względem repo root), posortowaną.
# ============================================================================

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ── Znajdź wszystkie pliki testowe ─────────────────────────────────────────
# Użycie: tf_discover [KATEGORIA]
#   KATEGORIA: unit | integration | e2e | security | drift | recovery |
#              reproducibility | clean-room | fault-injection | negative |
#              golden | snapshot | property | migration | performance |
#              meta | mutation | contract | (puste = wszystkie)
tf_discover() {
  local category="${1:-}"
  local search_dir="$TESTS_DIR"
  if [ -n "$category" ]; then
    search_dir="$TESTS_DIR/$category"
    if [ ! -d "$search_dir" ]; then
      tf_error "DISCOVER" "brak kategorii testów: $category"
      return 1
    fi
  fi
  local files
  files=$(find "$search_dir" -type f -name '*.test.sh' 2>/dev/null | sort)
  if [ -z "$files" ]; then
    # Pusty discovery = ERROR (nie cichy skip).
    tf_error "DISCOVER" "brak testów (*.test.sh) w $search_dir"
    return 1
  fi
  # Wypisz ścieżki względem repo root.
  local f
  for f in $files; do
    printf '%s\n' "${f#$REPO_ROOT/}"
  done
  return 0
}

# ── Policz testy w kategorii ───────────────────────────────────────────────
tf_discover_count() {
  local category="${1:-}"
  local search_dir="$TESTS_DIR"
  [ -n "$category" ] && search_dir="$TESTS_DIR/$category"
  find "$search_dir" -type f -name '*.test.sh' 2>/dev/null | wc -l
}
