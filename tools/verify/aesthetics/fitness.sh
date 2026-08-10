#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# aesthetics/fitness.sh — AIGON Production Platform — AESTHETICS PLANE
# Moduł: CONS-01 — GOLDEN PATH CONFORMANCE (fitness functions)
#
# Fitness functions dla golden path: "ten sam problem = to samo
# rozwiązanie". Każdy serwis i katalog z kodem MUSI mieć standardowy
# layout i standardowe targety. Odstępstwo od golden path = kandydat
# do waivera (NIGDY ciche ignorowanie).
#
# Golden path jest zdefiniowany w config/aesthetics/golden-path.yaml
# (layout + targety + exclude) — fitness.sh czyta ten plik, nie hardcode.
#
# Checki:
#   CONS-01-01  Layout projektu — każdy katalog serwisu ma standardowy layout
#   CONS-01-02  Standardowe targety — każdy katalog z kodem ma test/verify/deploy
#   CONS-01-03  Struktura katalogów — brak pustych katalogów, brak duplikatów konwencji
#   CONS-01-04  Golden path score — agregacja fitness; <100% = FAIL (BLOCKING)
#   CONS-01-05  Fitness score raport (informational)
#
# Fail-closed: brak golden-path.yaml (źródło prawdy) = FAIL (BLOCKING).
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

GOLDEN_PATH="$ROOT/config/aesthetics/golden-path.yaml"

say "=== AESTHETICS — GOLDEN PATH CONFORMANCE (CONS-01) ==="

# ── Fail-closed: golden-path.yaml to źródło prawdy ──────────
if [ ! -f "$GOLDEN_PATH" ]; then
  fail "CONS-01-01 Layout projektu" BLOCKING "Brak źródła prawdy: $GOLDEN_PATH — golden-path.yaml nie istnieje (fail-closed)."
  fail "CONS-01-02 Standardowe targety" BLOCKING "Brak golden-path.yaml — nie można zweryfikować targetów."
  fail "CONS-01-03 Struktura katalogów" BLOCKING "Brak golden-path.yaml — nie można zweryfikować struktury."
  fail "CONS-01-04 Golden path score" BLOCKING "Brak golden-path.yaml — nie można policzyć fitness score."
  info "CONS-01-05 Fitness score raport" "Brak golden-path.yaml — brak danych do raportu."
  evidence_record "verify:aesthetics:cons-01" "module" "aesthetics/fitness.sh"
  verify_module_exit
fi

# ── Parser YAML (grep/sed, bez jq — wzorzec repo) ───────────
# Parsuje golden-path.yaml do zmiennych globalnych:
#   GP_REQUIRED_FILES  — lista plików wymaganych w katalogu serwisu
#   GP_REQUIRED_DIRS   — lista katalogów wymaganych w katalogu serwisu
#   GP_TARGET_TEST     — lista komend akceptowalnych dla targetu test
#   GP_TARGET_VERIFY   — lista komend akceptowalnych dla targetu verify
#   GP_TARGET_DEPLOY   — lista komend akceptowalnych dla targetu deploy
#   GP_SERVICE_ROOTS   — lista katalogów, których podkatalogi to serwisy
#   GP_EXCLUDE         — lista katalogów wykluczonych (regex alternatyw)
# Zwraca 0 = sukces, 1 = błąd parsowania.
parse_golden_path() {
  local f="$1"
  GP_REQUIRED_FILES=""
  GP_REQUIRED_DIRS=""
  GP_TARGET_TEST=""
  GP_TARGET_VERIFY=""
  GP_TARGET_DEPLOY=""
  GP_SERVICE_ROOTS=""
  GP_EXCLUDE=""

  # required_files: [Makefile, README.md]
  GP_REQUIRED_FILES="$(sed -n 's/^[[:space:]]*required_files:[[:space:]]*\[\(.*\)\]/\1/p' "$f" | tr ',' ' ')"
  # required_dirs: [src, tests]
  GP_REQUIRED_DIRS="$(sed -n 's/^[[:space:]]*required_dirs:[[:space:]]*\[\(.*\)\]/\1/p' "$f" | tr ',' ' ')"
  # targets: test/verify/deploy — linie "test: [make test, npm test, ...]"
  GP_TARGET_TEST="$(sed -n 's/^[[:space:]]*test:[[:space:]]*\[\(.*\)\]/\1/p' "$f" | tr ',' '|')"
  GP_TARGET_VERIFY="$(sed -n 's/^[[:space:]]*verify:[[:space:]]*\[\(.*\)\]/\1/p' "$f" | tr ',' '|')"
  GP_TARGET_DEPLOY="$(sed -n 's/^[[:space:]]*deploy:[[:space:]]*\[\(.*\)\]/\1/p' "$f" | tr ',' '|')"
  # service_roots: [apps, agents]
  GP_SERVICE_ROOTS="$(sed -n 's/^[[:space:]]*service_roots:[[:space:]]*\[\(.*\)\]/\1/p' "$f" | tr ',' ' ')"
  # exclude: [.git, .github, ...] — budujemy regex alternatyw z opcjonalnym "/"
  local excl
  excl="$(sed -n 's/^[[:space:]]*exclude:[[:space:]]*\[\(.*\)\]/\1/p' "$f" | tr ',' ' ')"
  GP_EXCLUDE=""
  local e
  for e in $excl; do
    e="$(printf '%s' "$e" | tr -d '[:space:]')"
    [ -z "$e" ] && continue
    if [ -n "$GP_EXCLUDE" ]; then GP_EXCLUDE="$GP_EXCLUDE|"; fi
    GP_EXCLUDE="$GP_EXCLUDE^$e/?$"
  done

  # Fail-closed: wymagane pola muszą być niepuste.
  if [ -z "$GP_REQUIRED_FILES" ] || [ -z "$GP_REQUIRED_DIRS" ] || \
     [ -z "$GP_TARGET_TEST" ] || [ -z "$GP_TARGET_VERIFY" ] || [ -z "$GP_TARGET_DEPLOY" ] || \
     [ -z "$GP_SERVICE_ROOTS" ]; then
    return 1
  fi
  return 0
}

# ── Katalogi serwisów ───────────────────────────────────────
# Katalog serwisu = bezpośredni podkatalog service_root (np. apps/agent,
# agents/runtime). Rooty serwisów (apps, agents) same NIE są serwisami.
# Zwraca listę katalogów serwisów (jedna na linię).
service_dirs() {
  local root d
  for root in $GP_SERVICE_ROOTS; do
    # Bezpośrednie podkatalogi roota (głębokość 1): dla każdego git-tracked
    # pliku pod rootem wyciągamy pierwszy segment ścieżki (np. apps/agent).
    while IFS= read -r d; do
      [ -z "$d" ] && continue
      # Pomiń katalogi wykluczone.
      if [ -n "$GP_EXCLUDE" ] && printf '%s' "$d" | grep -qE "$GP_EXCLUDE"; then
        continue
      fi
      printf '%s\n' "$d"
    done < <(repo_files --dir "$root" | sed -n "s#^$root/\([^/]*\)/.*#$root/\1#p" | sort -u)
  done
}

# ── Katalogi z kodem ────────────────────────────────────────
# Katalog z kodem = zawiera Makefile / package.json / Cargo.toml / go.mod.
# Zwraca listę katalogów z kodem (jedna na linię).
code_dirs() {
  local d
  while IFS= read -r d; do
    [ "$d" = "." ] && continue
    if [ -n "$GP_EXCLUDE" ] && printf '%s' "$d" | grep -qE "$GP_EXCLUDE"; then
      continue
    fi
    if [ -f "$d/Makefile" ] || [ -f "$d/package.json" ] || \
       [ -f "$d/Cargo.toml" ] || [ -f "$d/go.mod" ]; then
      printf '%s\n' "$d"
    fi
  done < <(repo_files | xargs -n1 dirname 2>/dev/null | sort -u)
}

# ── Czy katalog ma target? ──────────────────────────────────
# Sprawdza, czy katalog z kodem ma dany target (test/verify/deploy).
# Argumenty: <katalog> <target> <regex_komend>
# Zwraca 0 = ma target, 1 = brak.
has_target() {
  local dir="$1" target="$2" regex="$3"
  # Makefile: szukamy targetu "target:" na początku linii.
  if [ -f "$dir/Makefile" ]; then
    if grep -qE "^[[:space:]]*${target}:" "$dir/Makefile"; then
      return 0
    fi
  fi
  # package.json: szukamy "scripts": { "test": ... } — komenda z regex.
  if [ -f "$dir/package.json" ]; then
    if grep -qE "\"${target}\"[[:space:]]*:" "$dir/package.json"; then
      return 0
    fi
  fi
  # Cargo.toml / go.mod: targety przez make (jeśli Makefile istnieje) —
  # już obsłużone powyżej. Dla Cargo/go bez Makefile nie ma standardowego
  # targetu verify/deploy — to odstępstwo (raportowane przez CONS-01-02).
  return 1
}

# ── Parsowanie golden path ──────────────────────────────────
if ! parse_golden_path "$GOLDEN_PATH"; then
  fail "CONS-01-01 Layout projektu" BLOCKING "golden-path.yaml ma niepoprawną strukturę (brak wymaganych pól)."
  fail "CONS-01-02 Standardowe targety" BLOCKING "golden-path.yaml ma niepoprawną strukturę (brak targetów)."
  fail "CONS-01-03 Struktura katalogów" BLOCKING "golden-path.yaml ma niepoprawną strukturę (brak exclude)."
  fail "CONS-01-04 Golden path score" BLOCKING "golden-path.yaml ma niepoprawną strukturę — nie można policzyć fitness."
  info "CONS-01-05 Fitness score raport" "Brak poprawnych danych golden path."
  evidence_record "verify:aesthetics:cons-01" "module" "aesthetics/fitness.sh"
  verify_module_exit
fi

# ── CONS-01-01 Layout projektu ──────────────────────────────
say ""
say "--- CONS-01-01: Layout projektu (standardowy layout serwisu) ---"
# WHY: każdy serwis musi mieć ten sam szkielet (README + Makefile + src/ + tests/),
# inaczej onboarding wymaga nauki nowego layoutu per serwis (cognitive load).
# SOURCE: aesthetics-plane-design.md (CONS-01 golden path conformance).
# EVIDENCE: obecność required_files + required_dirs w każdym katalogu serwisu.
# EXPECTED: każdy katalog serwisu ma wszystkie wymagane elementy.
# ACTUAL: lista odstępstw. SEVERITY: BLOCKING.
# REMEDIATION: dodaj brakujące elementy layoutu (lub zgłoś waiver).
LAYOUT_VIOLATIONS=0
LAYOUT_DETAIL=""
while IFS= read -r d; do
  missing=""
  for f in $GP_REQUIRED_FILES; do
    if [ ! -f "$d/$f" ]; then
      missing="$missing $f"
    fi
  done
  for dd in $GP_REQUIRED_DIRS; do
    if [ ! -d "$d/$dd" ]; then
      missing="$missing $dd/"
    fi
  done
  if [ -n "$missing" ]; then
    LAYOUT_VIOLATIONS=$((LAYOUT_VIOLATIONS+1))
    LAYOUT_DETAIL="$LAYOUT_DETAIL [$d: brak$missing]"
  fi
done < <(service_dirs)

if [ "$LAYOUT_VIOLATIONS" -eq 0 ]; then
  pass "CONS-01-01 Layout projektu" BLOCKING "Wszystkie katalogi serwisów mają standardowy layout."
else
  fail "CONS-01-01 Layout projektu" BLOCKING "$LAYOUT_VIOLATIONS katalogów serwisów bez standardowego layoutu:$LAYOUT_DETAIL"
fi

# ── CONS-01-02 Standardowe targety ──────────────────────────
say ""
say "--- CONS-01-02: Standardowe targety (test/verify/deploy) ---"
# WHY: `make test/verify/deploy` wszędzie = jeden sposób uruchomienia każdego
# serwisu. Brak targetu = nie wiadomo jak testować/weryfikować/wdrażać.
# SOURCE: aesthetics-plane-design.md (CONS-01 — standardowe targety wszędzie).
# EVIDENCE: obecność targetów test/verify/deploy w każdym katalogu z kodem.
# EXPECTED: każdy katalog z kodem ma wszystkie 3 targety.
# ACTUAL: lista katalogów z brakującymi targetami.
# SEVERITY: BLOCKING. REMEDIATION: dodaj brakujące targety (lub zgłoś waiver).
TARGET_VIOLATIONS=0
TARGET_DETAIL=""
CODE_DIR_COUNT=0
while IFS= read -r d; do
  CODE_DIR_COUNT=$((CODE_DIR_COUNT+1))
  missing=""
  if ! has_target "$d" "test" "$GP_TARGET_TEST"; then missing="$missing test"; fi
  if ! has_target "$d" "verify" "$GP_TARGET_VERIFY"; then missing="$missing verify"; fi
  if ! has_target "$d" "deploy" "$GP_TARGET_DEPLOY"; then missing="$missing deploy"; fi
  if [ -n "$missing" ]; then
    TARGET_VIOLATIONS=$((TARGET_VIOLATIONS+1))
    TARGET_DETAIL="$TARGET_DETAIL [$d: brak$missing]"
  fi
done < <(code_dirs)

if [ "$CODE_DIR_COUNT" -eq 0 ]; then
  # Fail-closed, ale uczciwie: brak kodu w repo = brak odstępstw do zgłoszenia.
  # To NIE jest conformance 0% — nie ma katalogów z kodem, więc nie ma czego
  # sprawdzać. Raportujemy jako INFO (nie FAIL), bo nie ma problemu.
  info "CONS-01-02 Standardowe targety" "Brak katalogów z kodem (Makefile/package.json/Cargo.toml/go.mod) w repo — brak targetów do weryfikacji."
elif [ "$TARGET_VIOLATIONS" -eq 0 ]; then
  pass "CONS-01-02 Standardowe targety" BLOCKING "Wszystkie $CODE_DIR_COUNT katalogów z kodem mają targety test/verify/deploy."
else
  fail "CONS-01-02 Standardowe targety" BLOCKING "$TARGET_VIOLATIONS/$CODE_DIR_COUNT katalogów z kodem bez standardowych targetów:$TARGET_DETAIL"
fi

# ── CONS-01-03 Struktura katalogów ──────────────────────────
say ""
say "--- CONS-01-03: Struktura katalogów (brak chaosu) ---"
# WHY: spójna struktura = przewidywalność. Puste katalogi i duplikaty konwencji
# (np. dwa pliki buildowe w jednym katalogu) to chaos, który podnosi cognitive load.
# SOURCE: aesthetics-plane-design.md (CONS-01 — struktura katalogów).
# EVIDENCE: skan katalogów pod kątem pustych katalogów i duplikatów konwencji.
# EXPECTED: brak pustych katalogów, brak duplikatów plików buildowych.
# ACTUAL: lista naruszeń. SEVERITY: WARNING (nie blokuje, ale wymaga decyzji).
# REMEDIATION: usuń puste katalogi / zduplikowane pliki buildowe (lub waiver).
STRUCT_VIOLATIONS=0
STRUCT_DETAIL=""
# Duplikaty konwencji: katalog z kodem ma >1 plik buildowy (np. Makefile + package.json).
while IFS= read -r d; do
  build_count=0
  [ -f "$d/Makefile" ] && build_count=$((build_count+1))
  [ -f "$d/package.json" ] && build_count=$((build_count+1))
  [ -f "$d/Cargo.toml" ] && build_count=$((build_count+1))
  [ -f "$d/go.mod" ] && build_count=$((build_count+1))
  if [ "$build_count" -gt 1 ]; then
    STRUCT_VIOLATIONS=$((STRUCT_VIOLATIONS+1))
    STRUCT_DETAIL="$STRUCT_DETAIL [$d: $build_count plików buildowych]"
  fi
done < <(code_dirs)

# Puste katalogi: katalog serwisu bez żadnych plików poza README.
while IFS= read -r d; do
  non_readme="$(repo_files --dir "$d" | grep -vE 'README\.md$' | grep -v '^$' || true)"
  if [ -z "$non_readme" ]; then
    STRUCT_VIOLATIONS=$((STRUCT_VIOLATIONS+1))
    STRUCT_DETAIL="$STRUCT_DETAIL [$d: katalog serwisu bez zawartości poza README]"
  fi
done < <(service_dirs)

if [ "$STRUCT_VIOLATIONS" -eq 0 ]; then
  pass "CONS-01-03 Struktura katalogów" WARNING "Brak pustych katalogów i duplikatów konwencji buildowych."
else
  warn "CONS-01-03 Struktura katalogów" "$STRUCT_VIOLATIONS naruszeń struktury:$STRUCT_DETAIL"
fi

# ── CONS-01-04 Golden path score (agregacja) ────────────────
say ""
say "--- CONS-01-04: Golden path score (agregacja fitness) ---"
# WHY: fitness score = % conformance. <100% = są odstępstwa = FAIL (BLOCKING),
# bo golden path to kontrakt, nie sugestia. Odstępstwa = kandydaci do waivera.
# SOURCE: aesthetics-plane-design.md (CONS-01 — golden path conformance %).
# EVIDENCE: agregacja CONS-01-01..03.
# EXPECTED: 100% conformance. ACTUAL: fitness score.
# SEVERITY: BLOCKING. REMEDIATION: napraw odstępstwa lub zgłoś waiver.
# Fitness = (spełnione wymagania) / (wszystkie wymagania).
# Wymagania: layout (per serwis) + targety (per katalog z kodem) + struktura.
# Upraszczamy: liczymy conformance jako 1 - (naruszenia / wymagania).
# Gdy nie ma wymagań (brak serwisów i kodu), conformance = 100% (vacuously true).
TOTAL_REQ=0
TOTAL_VIOL=0
# Layout: 1 wymaganie per katalog serwisu.
SVC_COUNT="$(service_dirs | grep -c . || true)"
SVC_COUNT="${SVC_COUNT:-0}"
TOTAL_REQ=$((TOTAL_REQ + SVC_COUNT))
TOTAL_VIOL=$((TOTAL_VIOL + LAYOUT_VIOLATIONS))
# Targety: 1 wymaganie per katalog z kodem.
TOTAL_REQ=$((TOTAL_REQ + CODE_DIR_COUNT))
TOTAL_VIOL=$((TOTAL_VIOL + TARGET_VIOLATIONS))
# Struktura: 1 wymaganie per katalog serwisu + per katalog z kodem.
TOTAL_REQ=$((TOTAL_REQ + SVC_COUNT + CODE_DIR_COUNT))
TOTAL_VIOL=$((TOTAL_VIOL + STRUCT_VIOLATIONS))

if [ "$TOTAL_REQ" -eq 0 ]; then
  FITNESS=100
else
  FITNESS=$(( (TOTAL_REQ - TOTAL_VIOL) * 100 / TOTAL_REQ ))
fi

if [ "$FITNESS" -ge 100 ]; then
  pass "CONS-01-04 Golden path score" BLOCKING "Golden path conformance: 100% ($TOTAL_REQ wymagań, 0 odstępstw)."
else
  fail "CONS-01-04 Golden path score" BLOCKING "Golden path conformance: $FITNESS% ($TOTAL_VIOL/$TOTAL_REQ odstępstw). Odstępstwa = kandydaci do waivera."
fi

# ── CONS-01-05 Fitness score raport (informational) ─────────
say ""
say "--- CONS-01-05: Fitness score raport (informational) ---"
# WHY: raport fitness score jako INFO — metryka do scorecarda (wymiar CONS,
# "golden path conformance %" z design doca). Nie blokuje, ale jest widoczna.
# SOURCE: aesthetics-plane-design.md (wymiar 11 — Spójność: golden path conformance %).
# EVIDENCE: fitness score. EXPECTED: raport. ACTUAL: fitness score.
# SEVERITY: INFORMATIONAL.
info "CONS-01-05 Fitness score raport" "golden path conformance: ${FITNESS}% (layout=$SVC_COUNT serwisów, targety=$CODE_DIR_COUNT katalogów z kodem, struktura=$STRUCT_VIOLATIONS naruszeń)"

# ── Evidence: moduł zakończony ──────────────────────────────
evidence_record "verify:aesthetics:cons-01" "module" "aesthetics/fitness.sh"

verify_module_exit
