#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# aesthetics/qi.sh — AIGON Production Platform — Quality Index Calculator
# Moduł: AESTHETICS PLANE — KALKULATOR QI (wariant c)
# Query + scorecard: agregacja 14 wymiarów doskonałości w Quality Index
# (średnia geometryczna ważona).
#
# QI = 100 × ∏_{i=1}^{14} s_i^{w_i},  ∑ w_i = 1
#
# Średnia geometryczna, nie arytmetyczna — jeden wymiar na zero → cały
# indeks na zero. Nie da się "nadrobić" dziurawego bezpieczeństwa pięknym
# kodem. Doskonałość = brak słabych ogniw.
#
# Checki:
#   QI-001  Query — tabela quality_index istnieje (migracja 0009 uruchomiona)
#   QI-002  Scorecard — 14 wierszy (wymiar, score, waga, wkład) + QI końcowy
#   QI-003  Świeżość evidence — dimension score bez świeżego evidence = 0
#           (nie NULL — ZERO). computed_at starszy niż próg z configu = 0.
#   QI-004  ΔQI — metryka konkurencyjna, porównanie z poprzednim computed_at
#   QI-005  Wagi z configu — wagi w_i z configu (tier1 vs tier3); brak
#           configu wag → równe wagi (1/14) + INFO.
#
# Fail-closed: brak tabeli quality_index (migracja nie uruchomiona) = FAIL
# (BLOCKING) z komunikatem "uruchom state.sh migrate".
#
# Konfiguracja (env, opcjonalna):
#   VERIFY_STATE_DB  — ścieżka do bazy StateStore (domyślnie canonical-state.db)
#   QI_TIER          — tier serwisu: default | tier1 | tier3 (domyślnie default)
#   QI_FRESHNESS_DAYS— próg świeżości evidence w dniach (domyślnie 7)
# ─────────────────────────────────────────────────────────────
set -u

# Wymuś kropkę jako separator dziesiętny (awk printf %f zależy od locale —
# w polskim locale dawałby przecinek, co psuje parsowanie i raporty).
export LC_NUMERIC=C

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

# ── Konfiguracja ────────────────────────────────────────────
# Baza StateStore: respektuj VERIFY_STATE_DB (testy używają izolowanej bazy),
# w przeciwnym razie domyślna ścieżka canonical-state.db.
DB="${VERIFY_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
TIER="${QI_TIER:-default}"
FRESHNESS_DAYS="${QI_FRESHNESS_DAYS:-7}"
WEIGHTS_FILE="$ROOT/config/aesthetics/qi-weights.yaml"

# 14 wymiarów doskonałości (numeracja z design doca)
DIMENSIONS=(dim1 dim2 dim3 dim4 dim5 dim6 dim7 dim8 dim9 dim10 dim11 dim12 dim13 dim14)

say "=== AESTHETICS PLANE — QUALITY INDEX (QI-001..005) ==="
say "Tier: $TIER | Freshness threshold: $FRESHNESS_DAYS dni | DB: $DB"

# ── Helper: czy sqlite3 jest dostępny ───────────────────────
if ! command -v sqlite3 >/dev/null 2>&1; then
  fail "QI-001 Query" BLOCKING "sqlite3 niedostępny — nie można odczytać quality_index."
  evidence_record "verify:aesthetics:qi:no-sqlite" "module" "aesthetics/qi.sh"
  verify_module_exit
fi

# ── QI-001 Query: tabela quality_index istnieje ─────────────
say ""
say "--- QI-001: Query (tabela quality_index istnieje) ---"
# WHY: kalkulator QI czyta z tabeli quality_index (materializowany stan).
# Brak tabeli = migracja 0009 nie uruchomiona = nie ma skąd liczyć QI.
# SOURCE: docs/architecture/aesthetics-plane-design.md (migracja 0009).
# EVIDENCE: sqlite_master dla tabeli quality_index.
# EXPECTED: tabela istnieje. ACTUAL: obecność/brak tabeli.
# SEVERITY: BLOCKING. REMEDIATION: uruchom state.sh migrate.
if [ ! -f "$DB" ]; then
  fail "QI-001 Query" BLOCKING "Brak bazy StateStore: $DB — uruchom state.sh migrate (migracja 0009 tworzy quality_index)."
  evidence_record "verify:aesthetics:qi:no-db" "module" "aesthetics/qi.sh"
  verify_module_exit
fi

TABLE_OK=0
if sqlite3 "$DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='quality_index';" 2>/dev/null | grep -q 'quality_index'; then
  TABLE_OK=1
  pass "QI-001 Query" BLOCKING "Tabela quality_index istnieje (migracja 0009 uruchomiona)."
else
  fail "QI-001 Query" BLOCKING "Brak tabeli quality_index — uruchom state.sh migrate (migracja 0009 tworzy quality_index)."
  evidence_record "verify:aesthetics:qi:no-table" "module" "aesthetics/qi.sh"
  verify_module_exit
fi

# ── QI-005 Wagi z configu ───────────────────────────────────
say ""
say "--- QI-005: Wagi z configu (tier: $TIER) ---"
# WHY: wagi w_i zależą od tieru serwisu (tier1: bezpieczeństwo/odporność
# ważniejsze; tier3: piękno/spójność ważniejsze). Brak configu = równe wagi.
# SOURCE: config/aesthetics/qi-weights.yaml.
# EVIDENCE: wagi z YAML dla wybranego tieru.
# EXPECTED: wagi sumują się do 1.0. ACTUAL: suma wag.
# SEVERITY: WARNING (brak configu nie blokuje — użyj równych wag).
# REMEDIATION: dodaj qi_weights.<tier> do qi-weights.yaml.
WEIGHTS=""
WEIGHTS_SUM=""
if command -v python3 >/dev/null 2>&1 && python3 -c "import yaml" >/dev/null 2>&1; then
  if [ -f "$WEIGHTS_FILE" ]; then
    # Wczytaj wagi dla wybranego tieru (fallback: default). Wypisuje linie
    # "dimN=waga" oraz sumę w ostatniej linii "__SUM__<wartość>".
    WEIGHTS="$(python3 - "$WEIGHTS_FILE" "$TIER" <<'PYEOF'
import sys, yaml
path, tier = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = yaml.safe_load(f) or {}
weights = (data.get("qi_weights") or {}).get(tier) or (data.get("qi_weights") or {}).get("default") or {}
if not weights:
    # Brak configu wag — równe wagi (1/14).
    weights = {f"dim{i}": 1.0/14.0 for i in range(1, 15)}
total = sum(float(v) for v in weights.values())
for i in range(1, 15):
    print(f"dim{i}={weights.get(f'dim{i}', 0.0)}")
print(f"__SUM__{total:.6f}")
PYEOF
)"
    WEIGHTS_SUM="$(printf '%s\n' "$WEIGHTS" | grep '__SUM__' | sed 's/__SUM__//')"
    WEIGHTS="$(printf '%s\n' "$WEIGHTS" | grep -v '__SUM__')"
  else
    warn "QI-005 Wagi z configu" "Brak pliku wag: $WEIGHTS_FILE — używam równych wag (1/14)."
  fi
else
  warn "QI-005 Wagi z configu" "Brak python3/yaml — używam równych wag (1/14)."
fi

# Fallback: równe wagi, jeśli nie wczytano z configu.
# 13 wymiarów po 0.0714 + ostatni 0.0718 = 1.0 (suma dokładnie 1.0).
if [ -z "$WEIGHTS" ]; then
  WEIGHTS=""
  i=0
  for d in "${DIMENSIONS[@]}"; do
    i=$((i+1))
    if [ "$i" -eq 14 ]; then
      WEIGHTS="$WEIGHTS
$d=0.0718"
    else
      WEIGHTS="$WEIGHTS
$d=0.0714"
    fi
  done
  WEIGHTS_SUM="1.000000"
  info "QI-005 Wagi z configu" "Brak configu wag — użyto równych wag (1/14)."
fi

# Weryfikacja sumy wag = 1.0 (tolerancja 0.001).
if [ -n "$WEIGHTS_SUM" ]; then
  SUM_OK=0
  if awk -v s="$WEIGHTS_SUM" 'BEGIN { exit !(s > 0.999 && s < 1.001) }'; then
    SUM_OK=1
    pass "QI-005 Wagi z configu" WARNING "Wagi (tier=$TIER) sumują się do $WEIGHTS_SUM."
  else
    warn "QI-005 Wagi z configu" "Suma wag = $WEIGHTS_SUM (oczekiwano 1.0) — wagi nie sumują się do 1.0."
  fi
fi

# ── QI-003 Świeżość evidence + QI-002 Scorecard + QI-004 ΔQI ──
say ""
say "--- QI-003: Świeżość evidence (score bez świeżego evidence = 0) ---"
# WHY: dimension score bez świeżego evidence = 0 (nie NULL — ZERO). Stary
# evidence (computed_at starszy niż próg) nie dowodzi bieżącej doskonałości.
# SOURCE: design doc — "Reguła: dimension score bez świeżego evidence = 0".
# EVIDENCE: computed_at najnowszego wiersza per wymiar vs próg świeżości.
# EXPECTED: każdy wymiar ma świeży computed_at. ACTUAL: liczba nieświeżych.
# SEVERITY: BLOCKING (nieświeży wymiar = 0 = ciągnie cały QI w dół).
# REMEDIATION: przelicz quality_index świeżym evidence.

# Pobierz najnowszy score per wymiar (MAX(computed_at)) + czy świeży.
# Wypisuje linie: <dimension>\t<score>\t<computed_at>\t<fresh(0/1)>
RAW="$(sqlite3 -separator $'\t' "$DB" "
SELECT dimension, score, computed_at,
       CASE WHEN computed_at >= datetime('now', '-$FRESHNESS_DAYS days') THEN 1 ELSE 0 END
FROM quality_index q
WHERE computed_at = (SELECT MAX(computed_at) FROM quality_index q2 WHERE q2.dimension = q.dimension)
ORDER BY dimension;
" 2>/dev/null)"

# Mapa score per wymiar (z uwzględnieniem świeżości).
declare -A SCORE_MAP
STALE_COUNT=0
DIM_WITH_EVIDENCE=0
while IFS=$'\t' read -r dim score computed fresh; do
  [ -z "$dim" ] && continue
  DIM_WITH_EVIDENCE=$((DIM_WITH_EVIDENCE+1))
  if [ "$fresh" = "1" ]; then
    SCORE_MAP["$dim"]="$score"
  else
    # Nieświeży evidence → score = 0 (nie NULL — ZERO).
    SCORE_MAP["$dim"]="0"
    STALE_COUNT=$((STALE_COUNT+1))
    say "       $dim: nieświeży evidence (computed_at=$computed) → score=0"
  fi
done <<< "$RAW"

if [ "$DIM_WITH_EVIDENCE" -eq 0 ]; then
  info "QI-003 Świeżość evidence" "Brak wierszy w quality_index — wszystkie wymiary = 0 (brak evidence)."
elif [ "$STALE_COUNT" -eq 0 ]; then
  pass "QI-003 Świeżość evidence" BLOCKING "Wszystkie $DIM_WITH_EVIDENCE wymiary mają świeży evidence."
else
  fail "QI-003 Świeżość evidence" BLOCKING "$STALE_COUNT wymiarów ma nieświeży evidence (score=0)."
fi

# ── QI-002 Scorecard + obliczenie QI ────────────────────────
say ""
say "--- QI-002: Scorecard (14 wymiarów) ---"
# WHY: scorecard to czytelny raport — wymiar, score, waga, wkład (w_i·ln s_i).
# QI = 100 × ∏ s_i^{w_i} = 100 × exp(∑ w_i·ln s_i). Średnia geometryczna.
# SOURCE: design doc (wzór QI). EVIDENCE: score z quality_index + wagi.
# EXPECTED: QI w [0,100]. ACTUAL: wyliczony QI.
# SEVERITY: INFORMATIONAL (raport). REMEDIATION: popraw słabe wymiary.

# Zbuduj wejście dla awk: "dimN score waga" per wymiar.
AWK_INPUT=""
for d in "${DIMENSIONS[@]}"; do
  score="${SCORE_MAP[$d]:-0}"
  w="$(printf '%s\n' "$WEIGHTS" | grep "^$d=" | cut -d= -f2)"
  [ -z "$w" ] && w="0.0714"
  AWK_INPUT="$AWK_INPUT
$d $score $w"
done

# Oblicz QI w awk (logarytmy naturalne; s=0 → ln(0)=-inf → QI=0).
# NF<3 pomija puste linie (wiodące/końcowe) — inaczej pusta linia ustawia
# s=0 i zeruje cały indeks.
QI="$(printf '%s\n' "$AWK_INPUT" | awk '
BEGIN { sum = 0.0; zero = 0 }
NF < 3 { next }
{
  s = $2 + 0.0; w = $3 + 0.0;
  if (s <= 0) { zero = 1; sum = -999999; }
  else if (!zero) { sum += w * log(s); }
}
END {
  if (zero) { printf "0.00"; }
  else { printf "%.2f", 100.0 * exp(sum); }
}')"

# Wypisz scorecard (czytelny raport).
printf '  %-6s %-8s %-8s %-10s\n' "Wymiar" "Score" "Waga" "Wkład"
printf '  %-6s %-8s %-8s %-10s\n' "------" "-----" "----" "-----"
for d in "${DIMENSIONS[@]}"; do
  score="${SCORE_MAP[$d]:-0}"
  w="$(printf '%s\n' "$WEIGHTS" | grep "^$d=" | cut -d= -f2)"
  [ -z "$w" ] && w="0.0714"
  # Wkład = w_i·ln(s_i) (dla s=0 → -inf, pokazujemy "-inf").
  if awk -v s="$score" 'BEGIN { exit !(s <= 0) }'; then
    contrib="-inf"
  else
    contrib="$(awk -v s="$score" -v w="$w" 'BEGIN { printf "%.4f", w*log(s) }')"
  fi
  printf '  %-6s %-8s %-8s %-10s\n' "$d" "$score" "$w" "$contrib"
done
say ""
say "  QI (średnia geometryczna ważona) = $QI / 100"

# ── QI-004 ΔQI: porównanie z poprzednim computed_at ────────
say ""
say "--- QI-004: ΔQI (metryka konkurencyjna, tydzień do tygodnia) ---"
# WHY: ΔQI mierzy prędkość jakości — czy system się poprawia tydzień do
# tygodnia. Porównujemy QI z najnowszego computed_at vs poprzedniego.
# SOURCE: design doc — "Metryka konkurencyjna: ΔQI tydzień do tygodnia".
# EVIDENCE: dwa najnowsze computed_at w quality_index.
# EXPECTED: ΔQI >= 0 (poprawa). ACTUAL: ΔQI.
# SEVERITY: INFORMATIONAL (raport trendu).
# REMEDIATION: jeśli ΔQI < 0, popraw słabe wymiary.

# Pobierz dwa najnowsze computed_at (różne).
COMPUTED_AT="$(sqlite3 "$DB" "SELECT DISTINCT computed_at FROM quality_index ORDER BY computed_at DESC LIMIT 2;" 2>/dev/null)"
LATEST="$(printf '%s\n' "$COMPUTED_AT" | sed -n '1p')"
PREV="$(printf '%s\n' "$COMPUTED_AT" | sed -n '2p')"

if [ -z "$LATEST" ]; then
  info "QI-004 ΔQI" "Brak computed_at w quality_index — brak danych do ΔQI."
elif [ -z "$PREV" ]; then
  info "QI-004 ΔQI" "Tylko jeden computed_at ($LATEST) — brak poprzedniego do porównania (baseline)."
else
  # Oblicz QI dla poprzedniego computed_at (te same wagi).
  PREV_RAW="$(sqlite3 -separator $'\t' "$DB" "
SELECT dimension, score FROM quality_index WHERE computed_at = '$PREV';
" 2>/dev/null)"
  declare -A PREV_MAP
  while IFS=$'\t' read -r dim score; do
    [ -z "$dim" ] && continue
    PREV_MAP["$dim"]="$score"
  done <<< "$PREV_RAW"
  PREV_AWK=""
  for d in "${DIMENSIONS[@]}"; do
    s="${PREV_MAP[$d]:-0}"
    w="$(printf '%s\n' "$WEIGHTS" | grep "^$d=" | cut -d= -f2)"
    [ -z "$w" ] && w="0.0714"
    PREV_AWK="$PREV_AWK
$d $s $w"
  done
  PREV_QI="$(printf '%s\n' "$PREV_AWK" | awk '
BEGIN { sum = 0.0; zero = 0 }
NF < 3 { next }
{
  s = $2 + 0.0; w = $3 + 0.0;
  if (s <= 0) { zero = 1; sum = -999999; }
  else if (!zero) { sum += w * log(s); }
}
END {
  if (zero) { printf "0.00"; }
  else { printf "%.2f", 100.0 * exp(sum); }
}')"
  DELTA="$(awk -v a="$QI" -v b="$PREV_QI" 'BEGIN { printf "%.2f", a - b }')"
  say "  QI($LATEST) = $QI"
  say "  QI($PREV)  = $PREV_QI"
  say "  ΔQI = $DELTA"
  if awk -v d="$DELTA" 'BEGIN { exit !(d >= 0) }'; then
    pass "QI-004 ΔQI" INFORMATIONAL "ΔQI = $DELTA (poprawa lub stabilizacja tydzień do tygodnia)."
  else
    warn "QI-004 ΔQI" "ΔQI = $DELTA (regresja tydzień do tygodnia)."
  fi
fi

# ── Evidence: moduł zakończony ──────────────────────────────
# Evidence bridge (P0#1): każdy gate zapisuje wynik do StateStore.
evidence_record "verify:aesthetics:qi:qi=$QI tier=$TIER" "module" "aesthetics/qi.sh"

verify_module_exit
