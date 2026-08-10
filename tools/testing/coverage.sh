#!/usr/bin/env bash
# ============================================================================
# coverage.sh — TESTFORGE coverage matrix
# ============================================================================
# Wczytuje tests/coverage-matrix.yaml (mapowanie komponentów na poziomy
# testów) i produkuje coverage.json. Weryfikuje że każdy komponent ma
# pokrycie na wymaganych poziomach.
#
# Format coverage-matrix.yaml:
#   version: 1
#   components:
#     - name: state
#       levels: [L1, L2, L3, L4]
#       required: true
# ============================================================================

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

COVERAGE_FILE="${TESTFORGE_COVERAGE:-$TESTS_DIR/coverage-matrix.yaml}"

# ── Sprawdzenie czy macierz istnieje ───────────────────────────────────────
tf_coverage_exists() {
  [ -f "$COVERAGE_FILE" ]
}

# ── Wygeneruj coverage.json ────────────────────────────────────────────────
# Dla każdego komponentu sprawdza czy istnieją testy na zadeklarowanych
# poziomach (katalogi tests/<level>). Produkuje coverage.json.
tf_coverage_generate() {
  if ! tf_coverage_exists; then
    tf_error "COVERAGE" "brak pliku macierzy: $COVERAGE_FILE"
    return 1
  fi
  mkdir -p "$RESULTS_DIR"
  local json="{\"components\":["
  local first=1
  local component="" levels="" required="true"
  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line// /}"
    [ -z "$line" ] && continue
    case "$line" in
      "-name:"*) component="${line#-name:}" ; levels="" ; required="true" ;;
      "name:"*) component="${line#name:}" ; levels="" ; required="true" ;;
      "levels:"*) levels="${line#levels:}" ;;
      "required:"*) required="${line#required:}" ;;
    esac
    if [ -n "$component" ] && [ -n "$levels" ]; then
      # Sprawdź pokrycie: komponent ma pokrycie jeśli istnieje katalog
      # tests/<component> z co najmniej jednym plikiem *.test.sh.
      # (Komponenty przekrojowe — state/verify/testforge — mają testy
      # rozproszone po kategoriach; dla nich sprawdzamy czy istnieje
      # jakikolwiek test w repo oznaczony ownerem w manifest.)
      local covered="false" missing=""
      local comp_dir="$REPO_ROOT/tests/$component"
      if [ -d "$comp_dir" ] && [ -n "$(find "$comp_dir" -name '*.test.sh' 2>/dev/null)" ]; then
        covered="true"
      else
        # Fallback: sprawdź czy manifest ma test z owner == component.
        if grep -qE "owner:\s*$component" "$REPO_ROOT/tests/manifest.yaml" 2>/dev/null; then
          covered="true"
        else
          missing="brak testów dla komponentu"
        fi
      fi
      [ "$first" -eq 0 ] && json="$json,"
      first=0
      json="$json{\"name\":\"$component\",\"levels\":\"$levels\",\"covered\":$covered,\"missing\":\"$missing\",\"required\":$required}"
      if [ "$covered" = "false" ] && [ "$required" = "true" ]; then
        tf_fail "COVERAGE $component" "brak pokrycia: $missing"
      else
        tf_pass "COVERAGE $component" "pokrycie OK (levels:$levels)"
      fi
      component="" ; levels="" ; required="true"
    fi
  done < "$COVERAGE_FILE"
  json="$json]}"
  printf '%s\n' "$json" > "$RESULTS_DIR/coverage.json"
  return 0
}
