#!/usr/bin/env bash
# ============================================================================
# manifest.sh — TESTFORGE manifest loader
# ============================================================================
# Wczytuje tests/manifest.yaml (lista testów, poziomy, właściciele,
# zależności) i udostępnia funkcje zapytań.
#
# Format manifest.yaml:
#   version: 1
#   tests:
#     - id: UNIT-001
#       name: ...
#       level: L1
#       path: tests/unit/...
#       owner: ...
#       depends: []
#       required: true
# ============================================================================

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

MANIFEST_FILE="${TESTFORGE_MANIFEST:-$TESTS_DIR/manifest.yaml}"

# ── Sprawdzenie czy manifest istnieje ──────────────────────────────────────
tf_manifest_exists() {
  [ -f "$MANIFEST_FILE" ]
}

# ── Wypisanie testów dla danego poziomu ────────────────────────────────────
# Użycie: tf_manifest_level <LEVEL>   (np. L1)
# Wypisuje ścieżki testów (path) dla poziomu. Zwraca 0 jeśli znaleziono,
# 1 jeśli brak (nigdy cichy skip — brak testów na poziomie to ERROR).
tf_manifest_level() {
  local level="$1"
  if ! tf_manifest_exists; then
    tf_error "MANIFEST" "brak pliku manifest: $MANIFEST_FILE"
    return 1
  fi
  # Parsuj YAML: znajdź bloki "- id:" i ich "level:" oraz "path:".
  # Prosty parser liniowy (wystarczający dla płaskiej listy).
  local current_id="" current_level="" current_path="" current_required="true"
  local found=0
  local out=""
  while IFS= read -r line; do
    line="${line%%#*}"   # usuń komentarz
    line="${line// /}"   # usuń spacje (prosty YAML)
    [ -z "$line" ] && continue
    case "$line" in
      "-id:"*) current_id="" ; current_level="" ; current_path="" ; current_required="true" ;;
      "id:"*) current_id="${line#id:}" ;;
      "level:"*) current_level="${line#level:}" ;;
      "path:"*) current_path="${line#path:}" ;;
      "required:"*) current_required="${line#required:}" ;;
    esac
    if [ -n "$current_id" ] && [ -n "$current_level" ] && [ -n "$current_path" ]; then
      if [ "$current_level" = "$level" ]; then
        out="$out $current_path"
        found=1
      fi
      current_id="" ; current_level="" ; current_path=""
    fi
  done < "$MANIFEST_FILE"
  if [ "$found" -eq 1 ]; then
    printf '%s\n' "$out"
    return 0
  else
    # Brak testów na poziomie = ERROR (nie cichy skip).
    tf_error "MANIFEST" "brak testów na poziomie $level w $MANIFEST_FILE"
    return 1
  fi
}

# ── Wypisanie wszystkich ścieżek testów ────────────────────────────────────
tf_manifest_all() {
  if ! tf_manifest_exists; then
    tf_error "MANIFEST" "brak pliku manifest: $MANIFEST_FILE"
    return 1
  fi
  local current_id="" current_path="" out=""
  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line// /}"
    [ -z "$line" ] && continue
    case "$line" in
      "-id:"*) current_id="" ; current_path="" ;;
      "id:"*) current_id="${line#id:}" ;;
      "path:"*) current_path="${line#path:}" ;;
    esac
    if [ -n "$current_id" ] && [ -n "$current_path" ]; then
      out="$out $current_path"
      current_id="" ; current_path=""
    fi
  done < "$MANIFEST_FILE"
  printf '%s\n' "$out"
  return 0
}

# ── Walidacja manifestu ────────────────────────────────────────────────────
# Sprawdza że każdy wpis ma id/name/level/path i że plik path istnieje.
tf_manifest_validate() {
  if ! tf_manifest_exists; then
    tf_error "MANIFEST" "brak pliku manifest: $MANIFEST_FILE"
    return 1
  fi
  local ok=1
  local current_id="" current_name="" current_level="" current_path=""
  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line// /}"
    [ -z "$line" ] && continue
    case "$line" in
      "-id:"*) current_id="" ; current_name="" ; current_level="" ; current_path="" ;;
      "id:"*) current_id="${line#id:}" ;;
      "name:"*) current_name="${line#name:}" ;;
      "level:"*) current_level="${line#level:}" ;;
      "path:"*) current_path="${line#path:}" ;;
    esac
    if [ -n "$current_id" ] && [ -n "$current_level" ] && [ -n "$current_path" ]; then
      if [ -z "$current_name" ]; then
        tf_fail "MANIFEST-VALIDATE $current_id" "brak pola name"
        ok=0
      fi
      if [ ! -f "$REPO_ROOT/$current_path" ]; then
        tf_fail "MANIFEST-VALIDATE $current_id" "brak pliku: $current_path"
        ok=0
      fi
      current_id="" ; current_name="" ; current_level="" ; current_path=""
    fi
  done < "$MANIFEST_FILE"
  [ "$ok" -eq 1 ] && tf_pass "MANIFEST-VALIDATE" "manifest spójny: $MANIFEST_FILE"
  return $((1 - ok))
}
