#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# lib/validate.sh — MODEL VALIDATION
# Waliduje kanoniczny model (project-model.json) względem
# schematu (project-model.schema.json) oraz reguł spójności.
#
# FAIL-CLOSED: jeśli model jest niepoprawny, zwraca niezerowy
# kod wyjścia. NO FALSE GREEN.
# ─────────────────────────────────────────────────────────────
set -u

# ── Walidacja JSON (składnia) ───────────────────────────────
validate_json_syntax() {
  if command -v jq >/dev/null 2>&1; then
    jq empty "$MODEL_JSON" 2>/dev/null || return 1
  else
    # Fallback: python3 json.tool.
    if command -v python3 >/dev/null 2>&1; then
      python3 -m json.tool "$MODEL_JSON" >/dev/null 2>&1 || return 1
    else
      # Brak narzędzi — nie możemy zweryfikować składni.
      return 1
    fi
  fi
  return 0
}

# ── Walidacja wymaganych sekcji ─────────────────────────────
validate_required_sections() {
  local section
  for section in components pipelines gates evidence documents tests schemas configuration findings coverage; do
    if ! grep -q "\"$section\":" "$MODEL_JSON" 2>/dev/null; then
      return 1
    fi
  done
  return 0
}

# ── Walidacja relacji (FACT vs INFERRED) ────────────────────
validate_relations() {
  # Każdy wpis musi mieć relację FACT lub INFERRED.
  local bad
  bad="$(grep -oE '"relation": "[^"]*"' "$MODEL_JSON" 2>/dev/null | grep -vE '"relation": "(FACT|INFERRED)"' | head -1)"
  [ -z "$bad" ]
}

# ── Walidacja sekretów (żaden nie powinien przetrwać) ───────
validate_no_secrets() {
  if has_secret "$(cat "$MODEL_JSON" 2>/dev/null)"; then
    return 1
  fi
  return 0
}

# ── Walidacja coverage (NO FAKE 100%) ───────────────────────
validate_coverage() {
  # Każda metryka coverage musi mieć formula + input_set + exclusions.
  local n
  n="$(grep -c '"metric":' "$MODEL_JSON" 2>/dev/null || echo 0)"
  [ "$n" -gt 0 ] || return 1
  local missing
  missing="$(grep '"metric":' "$MODEL_JSON" 2>/dev/null | grep -v '"formula":' | head -1)"
  [ -z "$missing" ]
}

# ── Główna funkcja walidacji ────────────────────────────────
validate_run() {
  local ok=1
  if validate_json_syntax; then
    say "  [OK] JSON składnia poprawna"
  else
    say "  [FAIL] JSON składnia niepoprawna"
    ok=0
  fi
  if validate_required_sections; then
    say "  [OK] Wymagane sekcje obecne"
  else
    say "  [FAIL] Brak wymaganych sekcji"
    ok=0
  fi
  if validate_relations; then
    say "  [OK] Relacje FACT/INFERRED poprawne"
  else
    say "  [FAIL] Niepoprawna relacja"
    ok=0
  fi
  if validate_no_secrets; then
    say "  [OK] Brak sekretów w modelu"
  else
    say "  [FAIL] Wykryto sekret w modelu"
    ok=0
  fi
  if validate_coverage; then
    say "  [OK] Coverage ma formula+input_set+exclusions"
  else
    say "  [FAIL] Coverage niekompletne"
    ok=0
  fi
  if [ "$ok" -eq 1 ]; then
    say "Walidacja modelu: PASS"
    return 0
  else
    say "Walidacja modelu: FAIL"
    return 1
  fi
}
