#!/usr/bin/env bash
# ============================================================================
# gen-pipelines.sh — Generator pipelines.sh z config/canonical/pipelines.yaml
# ============================================================================
# Czyta config/canonical/pipelines.yaml (metadata-driven) i GENERUJE
# tools/automation/core/pipelines.sh. To jest JEDYNE źródło prawdy dla
# definicji pipeline'ów — NIE edytuj pipelines.sh ręcznie.
#
# Użycie:
#   bash tools/automation/core/gen-pipelines.sh
#
# Wymagania:
#   - bash, awk (fallback, gdy brak yq)
#   - opcjonalnie yq (jeśli dostępny, użyty; w przeciwnym razie awk)
#
# Idempotentność: wielokrotne uruchomienie daje identyczny wynik.
# ============================================================================
set -u

# ── Ścieżki ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PIPELINES_YAML="$REPO_ROOT/config/canonical/pipelines.yaml"
OUT_FILE="$SCRIPT_DIR/pipelines.sh"

if [ ! -f "$PIPELINES_YAML" ]; then
    echo "FATAL: brak pliku $PIPELINES_YAML" >&2
    exit 1
fi

# ── Parsowanie YAML ────────────────────────────────────────────────────────
# Wybieramy parser: yq (jeśli jest) albo awk (fallback).
# Wynik: linie "id|family|script|class|status|depends|contract" dla każdego pipeline'a
#        oraz "class|pipeline" dla list klas.
parse_pipelines() {
    if command -v yq >/dev/null 2>&1; then
        # yq: wypisz każdy pipeline jako "id|family|script|class|status|depends|contract"
        yq -r '.pipelines[] | "\(.id)|\(.family)|\(.script)|\(.class)|\(.status)|\(.depends | join(","))|\(.contract | join(","))"' "$PIPELINES_YAML"
    else
        # awk fallback: parsuje proste YAML (listy "- id:" i mapy "key: value")
        awk '
            /^  - id:/ { id=$3; family=""; script=""; class=""; status=""; depends=""; contract=""; next }
            /^    family:/ { family=$2; next }
            /^    script:/ { script=$2; next }
            /^    class:/ { class=$2; next }
            /^    status:/ { status=$2; next }
            /^    depends:/ {
                # "depends: [P-001, P-002]" → "P-001,P-002"
                line=$0
                sub(/^[ \t]*depends:[ \t]*/, "", line)
                gsub(/[\[\] ]/, "", line)
                depends=line
                next
            }
            /^    contract:/ {
                # "contract: [DISCOVER, CONTRACT, ...]" → "DISCOVER,CONTRACT,..."
                line=$0
                sub(/^[ \t]*contract:[ \t]*/, "", line)
                gsub(/[\[\] ]/, "", line)
                contract=line
                if (id != "") {
                    print id "|" family "|" script "|" class "|" status "|" depends "|" contract
                }
                id=""
                next
            }
        ' "$PIPELINES_YAML"
    fi
}

# ── Budowa wygenerowanego pliku ────────────────────────────────────────────
{
    cat <<'HEADER'
#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# pipelines.sh — AIGON Production Platform — Pipeline Operating System
# Katalog pipeline'ów (P-001..P-051) i mapowanie klas na pipeline'y.
#
# Klasy wykonania:
#   FAST       — <10s, pre-commit, oczywiste błędy
#   STANDARD   — <1-3min, pre-push, pełna certyfikacja lokalna
#   DEEP       — minuty, CI, niezależna weryfikacja
#   RELEASE    — pełna certyfikacja baseline/release
#   CONTINUOUS — ciągłe monitorowanie / asynchroniczne
# ─────────────────────────────────────────────────────────────
# GENERATED FILE — DO NOT EDIT. Edytuj config/canonical/pipelines.yaml
# i uruchom tools/automation/core/gen-pipelines.sh.
# ─────────────────────────────────────────────────────────────

# ── Pipeline'y i ich metadane ───────────────────────────────
# Format: <id>|<family>|<script>|<class>|<status>|<depends>|<contract>
#   id       — P-<seq>
#   family   — PRODUCT | DESIGN | SECURITY | CODE | BUILD | DEPLOYMENT | RUNTIME | RECOVERY
#   script   — ścieżka względem tools/automation/
#   class    — FAST | STANDARD | DEEP | RELEASE | CONTINUOUS
#   status   — IMPLEMENTED | PROPOSED
#   depends  — pipeline'y, które muszą przejść PRZED tym (przecinkami)
#   contract — 8 faz Pipeline Contract (przecinkami)

PIPELINES=(
HEADER

    # Wypisz PIPELINES w kolejności z YAML (P-001, P-002, ...).
    parse_pipelines | awk -F'|' '
        {
            id=$1; family=$2; script=$3; class=$4; status=$5; depends=$6; contract=$7
            printf "  \"%s|%s|%s|%s|%s|%s|%s\"\n", id, family, script, class, status, depends, contract
        }
    '

    cat <<'MID'
)

# ── Klasa → pipeline'y ──────────────────────────────────────
# Każda klasa uruchamia listę pipeline'ów z domyślną klasą.
pipeline_class_modules() {
  local class="$1"
  case "$class" in
MID

    # Wypisz case dla klas z YAML (sekcja classes:).
    # UWAGA: deduplikujemy klucze klas (last-wins). Duplikaty kluczy w YAML
    # powodowałyby zduplikowane case branches, a bash case first-match-wins
    # pomijałby późniejsze warianty. Last-wins gwarantuje, że ostatnia
    # definicja klasy wygrywa.
    awk '
        /^classes:/ { in_classes=1; next }
        in_classes && /^  [A-Z]+:/ {
            line=$0
            sub(/^[ \t]*/, "", line)
            split(line, a, ":")
            class=a[1]
            rest=substr(line, index(line, ":")+1)
            gsub(/[\[\] ]/, "", rest)
            gsub(/,/, " ", rest)
            if (!(class in classes)) { order[++n]=class }
            classes[class]=rest
            next
        }
        in_classes && /^[a-z]+:/ { in_classes=0 }
        END {
            for (i=1; i<=n; i++) {
                c=order[i]
                print "    " c ")"
                print "      echo \"" classes[c] "\""
                print "      ;;"
            }
        }
    ' "$PIPELINES_YAML"

    cat <<'MID2'
    *)
      echo ""
      ;;
  esac
}
MID2

    cat <<'FOOT'
# ── Mapowanie id pipeline'a → ścieżka skryptu ───────────────
# Każdy pipeline zadeklarowany w PIPELINES ma odpowiadający skrypt
# w tools/automation/<rodzina>/<nazwa>.sh. To jest JEDYNE miejsce mapowania —
# pipelines.sh deklaruje pipeline'y, automation.sh je uruchamia, a P-039
# (PIPELINE GOVERNANCE) weryfikuje integralność (każdy zadeklarowany pipeline
# MUSI istnieć). Rozjazd (FALSE GATE) jest tu eliminowany.
pipeline_script() {
  local id="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      local family="${rest%%|*}"
      rest="${rest#*|}"
      local script="${rest%%|*}"
      echo "$script"
      return
    fi
  done
  echo ""
}

# ── Klasa pipeline'a ────────────────────────────────────────
pipeline_class() {
  local id="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      echo "${rest%%|*}"
      return
    fi
  done
  echo ""
}

# ── Status pipeline'a (IMPLEMENTED | PROPOSED) ──────────────
pipeline_status() {
  local id="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      echo "${rest%%|*}"
      return
    fi
  done
  echo ""
}

# ── Rodzina pipeline'a ──────────────────────────────────────
pipeline_family() {
  local id="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      echo "${rest%%|*}"
      return
    fi
  done
  echo ""
}

# ── Zależności pipeline'a (przecinkami) ─────────────────────
pipeline_depends() {
  local id="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      echo "${rest%%|*}"
      return
    fi
  done
  echo ""
}

# ── Kontrakt pipeline'a (przecinkami) ───────────────────────
pipeline_contract() {
  local id="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      echo "${rest%%|*}"
      return
    fi
  done
  echo ""
}

# ── Lista pipeline'ów w rodzinie ────────────────────────────
pipeline_family_list() {
  local family="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    local rest="${entry#*|}"
    local fam="${rest%%|*}"
    if [ "$fam" = "$family" ]; then
      printf '%s ' "$eid"
    fi
  done
  echo ""
}

# ── Lista pipeline'ów IMPLEMENTED ───────────────────────────
pipeline_implemented() {
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    local rest="${entry#*|}"
    rest="${rest#*|}"
    rest="${rest#*|}"
    rest="${rest#*|}"
    local st="${rest%%|*}"
    if [ "$st" = "IMPLEMENTED" ]; then
      printf '%s ' "$eid"
    fi
  done
  echo ""
}

# ── Lista pipeline'ów PROPOSED ──────────────────────────────
pipeline_proposed() {
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    local rest="${entry#*|}"
    rest="${rest#*|}"
    rest="${rest#*|}"
    rest="${rest#*|}"
    local st="${rest%%|*}"
    if [ "$st" = "PROPOSED" ]; then
      printf '%s ' "$eid"
    fi
  done
  echo ""
}
FOOT
} > "$OUT_FILE"

# ── Weryfikacja poprawności składni ────────────────────────────────────────
if ! bash -n "$OUT_FILE"; then
    echo "FATAL: wygenerowany $OUT_FILE ma błąd składni" >&2
    exit 1
fi

echo "OK: wygenerowano $OUT_FILE z $PIPELINES_YAML"
exit 0
