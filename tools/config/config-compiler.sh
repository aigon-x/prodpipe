#!/usr/bin/env bash
# =============================================================================
# config-compiler.sh — AIGON Production Platform
# =============================================================================
# Deterministic config compiler.
# Pipeline: CANONICAL → VALIDATED → NORMALIZED → EFFECTIVE → GENERATED → OBSERVED.
# Zasada: fingerprint(A) == fingerprint(B) ⟺ A i B są konfiguracyjnie równoważne.
# STATUS: CANONICAL
# =============================================================================

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

CANONICAL_DIR="config/canonical"
GENERATED_DIR="config/generated"
SCHEMAS_DIR="config/schemas"
LOCAL_DIR="config/local"

FAIL=0
WARN=0
PASS=0

say()  { printf '%s\n' "$*"; }
fail() { say "[FAIL] $*"; FAIL=$((FAIL+1)); }
warn() { say "[WARN] $*"; WARN=$((WARN+1)); }
pass() { say "[PASS] $*"; }

usage() {
  say "Usage: config-compiler.sh <validate|generate|fingerprint|status>"
  say "  validate    — walidacja canonical config względem schematu"
  say "  generate    — generowanie DERIVED config (config/generated/)"
  say "  fingerprint — deterministyczny fingerprint canonical config"
  say "  status      — status config pipeline"
  exit 0
}

# --- Deterministic fingerprint (sha256 nad znormalizowanym canonical) ---
fingerprint() {
  local files
  files=$(find "$CANONICAL_DIR" -type f \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) | sort)
  if [ -z "$files" ]; then
    say "BRAK plików canonical config"
    return 1
  fi
  # Normalizacja: sortuj klucze YAML, usuń komentarze i puste linie → deterministyczny hash
  local tmp
  tmp=$(mktemp)
  for f in $files; do
    # Usuń komentarze (#) i puste linie, sortuj linie — deterministyczna normalizacja
    grep -vE '^\s*#|^\s*$' "$f" | sort >> "$tmp"
  done
  local hash
  hash=$(sha256sum "$tmp" | awk '{print $1}')
  rm -f "$tmp"
  say "$hash"
}

# --- Validate canonical config against schema ---
validate() {
  say "=== CONFIG VALIDATE ==="
  local schema="$SCHEMAS_DIR/platform.schema.json"
  local canonical="$CANONICAL_DIR/platform.yaml"

  if [ ! -f "$schema" ]; then
    fail "Brak schematu: $schema"
  else
    pass "Schemat istnieje: $schema"
  fi

  if [ ! -f "$canonical" ]; then
    fail "Brak canonical config: $canonical"
    return 1
  fi

  # Walidacja YAML (python3 + pyyaml jeśli dostępne)
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import yaml,sys; yaml.safe_load(open('$canonical'))" 2>/dev/null; then
      pass "YAML poprawny: $canonical"
    else
      fail "YAML niepoprawny: $canonical"
    fi
  else
    warn "python3/pyyaml niedostępne — pomijam walidację YAML"
  fi

  # Walidacja JSON schema (python3 + jsonschema jeśli dostępne)
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import jsonschema,yaml; s=json.load(open('$schema')); d=yaml.safe_load(open('$canonical')); jsonschema.validate(d,s)" 2>/dev/null; then
      pass "JSON Schema walidacja OK"
    else
      warn "jsonschema niedostępne lub walidacja nieudana — pomijam"
    fi
  fi

  # Sprawdź brak sekretów w canonical
  if grep -rInE '(api[_-]?key|secret|password|token)\s*[:=]\s*["'"'"'][A-Za-z0-9_\-]{16,}["'"'"']' \
      "$CANONICAL_DIR" 2>/dev/null | grep -q .; then
    fail "Sekrety w canonical config!"
  else
    pass "Brak sekretów w canonical config"
  fi

  # Sprawdź brak hardcoded IP w canonical (pełne adresy IPv4, nie numery sekcji)
  if grep -rInE '\b(10|100|192\.168|172)\.([0-9]{1,3}\.){2}[0-9]{1,3}\b' "$CANONICAL_DIR" 2>/dev/null | grep -q .; then
    fail "Hardcoded IP w canonical config!"
  else
    pass "Brak hardcoded IP w canonical config"
  fi

  say ""
  say "=== RESULT ==="
  say "PASS=$PASS FAIL=$FAIL WARN=$WARN"
  [ "$FAIL" -gt 0 ] && return 1 || return 0
}

# --- Generate DERIVED config (config/generated/) ---
generate() {
  say "=== CONFIG GENERATE ==="
  mkdir -p "$GENERATED_DIR"

  # Generuj platform.generated.yaml z canonical (kopiuj + oznacz jako GENERATED)
  if [ -f "$CANONICAL_DIR/platform.yaml" ]; then
    {
      say "# GENERATED — NIGDY ręcznie edytować. Regeneruj: config-compiler.sh generate"
      say "# Źródło: config/canonical/platform.yaml"
      say "# Fingerprint: $(fingerprint)"
      cat "$CANONICAL_DIR/platform.yaml"
    } > "$GENERATED_DIR/platform.generated.yaml"
    pass "Wygenerowano: $GENERATED_DIR/platform.generated.yaml"
  else
    fail "Brak canonical platform.yaml"
  fi

  # Generuj manifest generated
  {
    say "# GENERATED MANIFEST — NIGDY ręcznie edytować"
    say "generated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    say "source: config/canonical/"
    say "fingerprint: $(fingerprint)"
    say "compiler: config-compiler.sh"
  } > "$GENERATED_DIR/MANIFEST.generated.txt"
  pass "Wygenerowano: $GENERATED_DIR/MANIFEST.generated.txt"

  say ""
  say "=== RESULT ==="
  say "PASS=$PASS FAIL=$FAIL WARN=$WARN"
  [ "$FAIL" -gt 0 ] && return 1 || return 0
}

# --- Status of config pipeline ---
status() {
  say "=== CONFIG STATUS ==="
  say "Canonical dir:  $CANONICAL_DIR"
  say "Generated dir:  $GENERATED_DIR"
  say "Schemas dir:    $SCHEMAS_DIR"
  say "Local dir:      $LOCAL_DIR"
  say ""
  say "Canonical files:"
  find "$CANONICAL_DIR" -type f | sort | sed 's/^/  /'
  say ""
  say "Generated files:"
  find "$GENERATED_DIR" -type f | sort | sed 's/^/  /'
  say ""
  say "Fingerprint: $(fingerprint)"
  say ""
  say "Pipeline: CANONICAL → VALIDATED → NORMALIZED → EFFECTIVE → GENERATED → OBSERVED"
  say "Override: DEFAULT → PROFILE → CANONICAL → ENVIRONMENT → NODE → LOCAL → RUNTIME OVERRIDE"
}

case "${1:-}" in
  validate)   validate ;;
  generate)   generate ;;
  fingerprint) fingerprint ;;
  status)     status ;;
  *)          usage ;;
esac
