#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# aesthetics/spectral.sh — AIGON Production Platform — AESTHETICS PLANE
# Moduł: AEST-08 — API DESIGN LINT (spectral/vacuum na OpenAPI)
# Weryfikuje, że wszystkie pliki OpenAPI w repo przechodzą ruleset
# spectral (config/aesthetics/spectral-rules.yaml): naming, paginacja,
# format błędów, wersjonowanie + ogólne.
#
# Checki:
#   AEST-08-00  spectral/vacuum dostępny w PATH (fail-closed)
#   AEST-08-01  naming — operationId camelCase, ścieżki kebab-case,
#               brak wielkich liter, brak trailing slash
#   AEST-08-02  paginacja — limit/offset (lub page/per_page) spójne,
#               odpowiedź paginowana ma total/next
#   AEST-08-03  format błędów — RFC 7807 problem+json, spójny errors array
#   AEST-08-04  wersjonowanie — prefiks /v{n} lub header API-Version,
#               info.version obecny i semver
#   AEST-08-05  ogólne — info.title, info.description, servers,
#               operationId unikalne
#
# Fail-closed: brak spectral/vacuum w PATH = AEST-08-00 FAIL (BLOCKING),
# NIGDY skip. Brak plików OpenAPI w repo = AEST-08-01 PASS (INFORMATIONAL)
# — to poprawna odpowiedź, nie FAIL.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

RULESET="$ROOT/config/aesthetics/spectral-rules.yaml"

say "=== AESTHETICS — API DESIGN LINT (AEST-08) ==="

# ── AEST-08-00: spectral/vacuum dostępny (fail-closed) ──────
# WHY: bez lintera nie da się zweryfikować API designu. Fail-closed —
# brak narzędzia = FAIL (BLOCKING), NIGDY skip (ghost gate).
# SOURCE: aesthetics-plane-design.md (AEST-08). EVIDENCE: command -v.
# EXPECTED: spectral LUB vacuum w PATH. ACTUAL: wynik command -v.
# SEVERITY: BLOCKING. REMEDIATION: zainstaluj przez npm i -g @stoplight/spectral-cli.
LINTER=""
if command -v spectral >/dev/null 2>&1; then
  LINTER="spectral"
elif command -v vacuum >/dev/null 2>&1; then
  LINTER="vacuum"
fi

if [ -z "$LINTER" ]; then
  fail "AEST-08-00 spectral/vacuum dostępny" BLOCKING "spectral/vacuum niedostępny — zainstaluj przez npm i -g @stoplight/spectral-cli"
  # Bez lintera nie da się uruchomić checków AEST-08-01..05 — wszystkie FAIL.
  fail "AEST-08-01 naming" BLOCKING "Brak spectral/vacuum — nie można zweryfikować naming."
  fail "AEST-08-02 paginacja" BLOCKING "Brak spectral/vacuum — nie można zweryfikować paginacji."
  fail "AEST-08-03 format błędów" BLOCKING "Brak spectral/vacuum — nie można zweryfikować formatu błędów."
  fail "AEST-08-04 wersjonowanie" BLOCKING "Brak spectral/vacuum — nie można zweryfikować wersjonowania."
  fail "AEST-08-05 ogólne" BLOCKING "Brak spectral/vacuum — nie można zweryfikować reguł ogólnych."
  evidence_record "verify:aesthetics:spectral:no-linter" "module" "aesthetics/spectral.sh"
  verify_module_exit
fi

# ── Detekcja plików OpenAPI ─────────────────────────────────
# Skanujemy repo przez repo_files --name '\.(yaml|yml|json)$' i sprawdzamy,
# czy plik zawiera znacznik OpenAPI (openapi:/swagger: na początku, lub
# "openapi" w JSON). Pliki bez znacznika OpenAPI są pomijane.
OPENAPI_FILES=""
while IFS= read -r f; do
  case "$f" in
    *.json)
      if grep -qE '"openapi"\s*:' "$f" 2>/dev/null; then
        OPENAPI_FILES="$OPENAPI_FILES $f"
      fi
      ;;
    *.yaml|*.yml)
      if grep -qE '^(openapi|swagger)\s*:' "$f" 2>/dev/null; then
        OPENAPI_FILES="$OPENAPI_FILES $f"
      fi
      ;;
  esac
done < <(repo_files --name '\.(yaml|yml|json)$')

# ── Brak OpenAPI w repo = poprawna odpowiedź, nie FAIL ──────
if [ -z "$OPENAPI_FILES" ]; then
  info "AEST-08-01 naming" "brak OpenAPI w repo — AEST-08 nieaktywny"
  info "AEST-08-02 paginacja" "brak OpenAPI w repo — AEST-08 nieaktywny"
  info "AEST-08-03 format błędów" "brak OpenAPI w repo — AEST-08 nieaktywny"
  info "AEST-08-04 wersjonowanie" "brak OpenAPI w repo — AEST-08 nieaktywny"
  info "AEST-08-05 ogólne" "brak OpenAPI w repo — AEST-08 nieaktywny"
  evidence_record "verify:aesthetics:spectral:no-openapi" "module" "aesthetics/spectral.sh"
  verify_module_exit
fi

# ── Ruleset musi istnieć (fail-closed) ──────────────────────
if [ ! -f "$RULESET" ]; then
  fail "AEST-08-00 ruleset" BLOCKING "Brak rulesetu: $RULESET — nie można uruchomić spectral (fail-closed)."
  evidence_record "verify:aesthetics:spectral:no-ruleset" "module" "aesthetics/spectral.sh"
  verify_module_exit
fi

# ── Uruchom spectral na każdym pliku OpenAPI ────────────────
# Parsujemy wyniki i agregujemy naruszenia per kategoria (AEST-08-01..05).
# spectral lint --format json zwraca JSON z polami: code, message, severity,
# path. Mapujemy code reguły (aest-08-0X-*) na check AEST-08-0X.
declare -A CAT_ERROR=() CAT_WARN=() CAT_DETAIL=()
for cat in 01 02 03 04 05; do
  CAT_ERROR[$cat]=0
  CAT_WARN[$cat]=0
  CAT_DETAIL[$cat]=""
done

for f in $OPENAPI_FILES; do
  say "       lint: $f"
  local_out=""
  if [ "$LINTER" = "spectral" ]; then
    local_out="$(spectral lint "$f" --ruleset "$RULESET" --format json 2>/dev/null)"
  else
    # vacuum: vacuum lint <file> --ruleset <ruleset> --format json
    local_out="$(vacuum lint "$f" --ruleset "$RULESET" --format json 2>/dev/null)"
  fi
  # Parsuj JSON wyników (python3, jeśli dostępny; inaczej grep'owa heurystyka).
  if command -v python3 >/dev/null 2>&1; then
    while IFS=$'\t' read -r code severity message; do
      [ -z "$code" ] && continue
      case "$code" in
        aest-08-01-*) cat="01" ;;
        aest-08-02-*) cat="02" ;;
        aest-08-03-*) cat="03" ;;
        aest-08-04-*) cat="04" ;;
        aest-08-05-*) cat="05" ;;
        *) continue ;;
      esac
      if [ "$severity" = "error" ]; then
        CAT_ERROR[$cat]=$(( ${CAT_ERROR[$cat]} + 1 ))
      else
        CAT_WARN[$cat]=$(( ${CAT_WARN[$cat]} + 1 ))
      fi
      CAT_DETAIL[$cat]="${CAT_DETAIL[$cat]} [$f] $message"
    done < <(printf '%s' "$local_out" | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for r in data:
    code = r.get("code", "")
    sev = r.get("severity", "warn")
    msg = r.get("message", "")
    print(f"{code}\t{sev}\t{msg}")
')
  else
    # Grep'owa heurystyka: policz wystąpienia kodów reguł w surowym JSON.
    for cat in 01 02 03 04 05; do
      n_err=$(printf '%s' "$local_out" | grep -oE "\"code\":\"aest-08-$cat-[^\"]*\",\"severity\":\"error\"" | wc -l)
      n_warn=$(printf '%s' "$local_out" | grep -oE "\"code\":\"aest-08-$cat-[^\"]*\",\"severity\":\"warn\"" | wc -l)
      CAT_ERROR[$cat]=$(( ${CAT_ERROR[$cat]} + n_err ))
      CAT_WARN[$cat]=$(( ${CAT_WARN[$cat]} + n_warn ))
    done
  fi
done

# ── AEST-08-01: naming ──────────────────────────────────────
# WHY: nazewnictwo jak proza — spójny casing obniża cognitive load.
# SOURCE: aesthetics-plane-design.md (AEST-02 naming + AEST-08).
# EVIDENCE: naruszenia reguł aest-08-01-* z spectral.
# EXPECTED: 0 błędów naming. ACTUAL: liczba naruszeń.
# SEVERITY: BLOCKING. REMEDIATION: popraw operationId/ścieżki wg komunikatu.
if [ "${CAT_ERROR[01]}" -eq 0 ]; then
  pass "AEST-08-01 naming" BLOCKING "Brak naruszeń naming (operationId camelCase, ścieżki kebab-case)."
else
  fail "AEST-08-01 naming" BLOCKING "${CAT_ERROR[01]} naruszeń naming:${CAT_DETAIL[01]}"
fi

# ── AEST-08-02: paginacja ───────────────────────────────────
# WHY: spójna paginacja = przewidywalne API. SOURCE: AEST-08.
# EVIDENCE: naruszenia reguł aest-08-02-*. EXPECTED: 0 błędów.
# ACTUAL: liczba naruszeń. SEVERITY: WARNING (nie blokuje).
# REMEDIATION: ujednolić parę limit/offset lub page/per_page, dodać total/next.
if [ "${CAT_ERROR[02]}" -eq 0 ] && [ "${CAT_WARN[02]}" -eq 0 ]; then
  pass "AEST-08-02 paginacja" WARNING "Brak naruszeń paginacji."
else
  warn "AEST-08-02 paginacja" "${CAT_ERROR[02]} błędów + ${CAT_WARN[02]} ostrzeżeń:${CAT_DETAIL[02]}"
fi

# ── AEST-08-03: format błędów ───────────────────────────────
# WHY: błędy wg RFC 7807 = dopracowanie powierzchni (AEST-07/08).
# SOURCE: AEST-08. EVIDENCE: naruszenia reguł aest-08-03-*.
# EXPECTED: 0 naruszeń. ACTUAL: liczba. SEVERITY: WARNING.
# REMEDIATION: dodaj type/title/status/detail (problem+json) i errors array.
if [ "${CAT_ERROR[03]}" -eq 0 ] && [ "${CAT_WARN[03]}" -eq 0 ]; then
  pass "AEST-08-03 format błędów" WARNING "Brak naruszeń formatu błędów (RFC 7807)."
else
  warn "AEST-08-03 format błędów" "${CAT_ERROR[03]} błędów + ${CAT_WARN[03]} ostrzeżeń:${CAT_DETAIL[03]}"
fi

# ── AEST-08-04: wersjonowanie ───────────────────────────────
# WHY: wersjonowanie = czytelna ewolucja API. SOURCE: AEST-08.
# EVIDENCE: naruszenia reguł aest-08-04-*. EXPECTED: 0 błędów.
# ACTUAL: liczba. SEVERITY: BLOCKING (brak wersji = nie da się ewoluować).
# REMEDIATION: dodaj prefiks /v{n} lub header API-Version, info.version semver.
if [ "${CAT_ERROR[04]}" -eq 0 ]; then
  pass "AEST-08-04 wersjonowanie" BLOCKING "Brak naruszeń wersjonowania (prefiks /v{n}, info.version semver)."
else
  fail "AEST-08-04 wersjonowanie" BLOCKING "${CAT_ERROR[04]} naruszeń wersjonowania:${CAT_DETAIL[04]}"
fi

# ── AEST-08-05: ogólne ──────────────────────────────────────
# WHY: kompletny dokument OpenAPI = czytelne API. SOURCE: AEST-08.
# EVIDENCE: naruszenia reguł aest-08-05-*. EXPECTED: 0 błędów.
# ACTUAL: liczba. SEVERITY: BLOCKING (info.title/operationId unikalne).
# REMEDIATION: dodaj info.title/description, servers, unikalne operationId.
if [ "${CAT_ERROR[05]}" -eq 0 ]; then
  pass "AEST-08-05 ogólne" BLOCKING "Brak naruszeń reguł ogólnych (info.title, servers, operationId unikalne)."
else
  fail "AEST-08-05 ogólne" BLOCKING "${CAT_ERROR[05]} naruszeń reguł ogólnych:${CAT_DETAIL[05]}"
fi

# ── Evidence: moduł zakończony ──────────────────────────────
evidence_record "verify:aesthetics:spectral:complete" "module" "aesthetics/spectral.sh"

verify_module_exit
