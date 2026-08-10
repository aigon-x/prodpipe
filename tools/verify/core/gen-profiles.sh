#!/usr/bin/env bash
# ============================================================================
# gen-profiles.sh — Generator profiles.sh z config/canonical/gates.yaml
# ============================================================================
# Czyta config/canonical/gates.yaml (metadata-driven) i GENERUJE
# tools/verify/core/profiles.sh. To jest JEDYNE źródło prawdy dla definicji
# gate'ów — NIE edytuj profiles.sh ręcznie.
#
# Użycie:
#   bash tools/verify/core/gen-profiles.sh
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
GATES_YAML="$REPO_ROOT/config/canonical/gates.yaml"
OUT_FILE="$SCRIPT_DIR/profiles.sh"

if [ ! -f "$GATES_YAML" ]; then
    echo "FATAL: brak pliku $GATES_YAML" >&2
    exit 1
fi

# ── Parsowanie YAML ────────────────────────────────────────────────────────
# Wybieramy parser: yq (jeśli jest) albo awk (fallback).
# Wynik: linie "module|script|profile|severity" dla każdego gate'a
#        oraz "profile|module" dla list profili.
parse_gates() {
    if command -v yq >/dev/null 2>&1; then
        # yq: wypisz każdy gate jako "module|script|profile|severity"
        yq -r '.gates[] | .module as $m | .script as $s | .profiles | to_entries[] | "\($m)|\($s)|\(.key)|\(.value)"' "$GATES_YAML"
    else
        # awk fallback: parsuje proste YAML (listy "- module:" i mapy "key: value")
        awk '
            /^  - module:/ { module=$3; script=""; next }
            /^    script:/ { script=$2; next }
            /^    profiles:/ { in_profiles=1; next }
            in_profiles && /^      [a-z]+:/ {
                # "      fast: BLOCKING" → profile=fast, severity=BLOCKING
                line=$0
                sub(/^[ \t]*/, "", line)
                split(line, a, ":")
                profile=a[1]
                severity=a[2]
                gsub(/^[ \t]+|[ \t]+$/, "", severity)
                if (module != "" && script != "") {
                    print module "|" script "|" profile "|" severity
                }
                next
            }
            in_profiles && /^  - module:/ { in_profiles=0 }
            /^profiles:/ { in_profiles=0 }
        ' "$GATES_YAML"
    fi
}

# ── Budowa wygenerowanego pliku ────────────────────────────────────────────
{
    cat <<'HEADER'
#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# profiles.sh — AIGON Production Platform — Repository Certification Engine
# Definicje profili (L0-L3) i mapowanie modułów na profile.
#
# Poziomy:
#   L0 FAST   — pre-commit, <5-10s, oczywiste błędy
#   L1 FULL   — pre-push, <1-3min, pełna certyfikacja lokalnego drzewa
#   L2 REMOTE — CI, niezależna weryfikacja
#   L3 RELEASE/GENESIS — pełna certyfikacja baseline/release
# ─────────────────────────────────────────────────────────────
# GENERATED FILE — DO NOT EDIT. Edytuj config/canonical/gates.yaml
# i uruchom tools/verify/core/gen-profiles.sh.
# ─────────────────────────────────────────────────────────────

# ── Moduły i ich klasy ───────────────────────────────────────
# Format: <module>:<profile>:<severity>
#   module   — nazwa modułu (git, security, structure, ...)
#   profile  — fast | full | security | architecture | reproducibility | release | genesis | all
#   severity — BLOCKING | WARNING | INFORMATIONAL

VERIFY_MODULES=(
HEADER

    # Wypisz VERIFY_MODULES w kolejności: moduł, potem profile wg kolejności
    # występowania w YAML. Zachowujemy kolejność z YAML (git, security, ...).
    parse_gates | awk -F'|' '
        {
            module=$1; script=$2; profile=$3; severity=$4
            key=module
            if (!(key in seen)) { order[++n]=key; seen[key]=1 }
            mods[key]=mods[key] "  \"" module ":" profile ":" severity "\"\n"
        }
        END {
            for (i=1; i<=n; i++) {
                m=order[i]
                printf "%s", mods[m]
            }
        }
    '

    cat <<'MID'
)

# ── Profile → moduły ─────────────────────────────────────────
# Każdy profil uruchamia listę modułów z domyślną klasą.
verify_profile_modules() {
  local profile="$1"
  case "$profile" in
MID

    # Wypisz case dla profili z YAML (sekcja profiles:).
    awk '
        /^profiles:/ { in_profiles=1; next }
        in_profiles && /^  [a-z]+:/ {
            line=$0
            sub(/^[ \t]*/, "", line)
            split(line, a, ":")
            profile=a[1]
            # reszta po ":" to lista [mod1, mod2, ...]
            rest=substr(line, index(line, ":")+1)
            gsub(/[\[\] ]/, "", rest)
            gsub(/,/, " ", rest)
            print "    " profile ")"
            print "      echo \"" rest "\""
            print "      ;;"
            next
        }
        in_profiles && /^[a-z]+:/ { in_profiles=0 }
    ' "$GATES_YAML"

    cat <<'MID2'
    *)
      echo "git security structure"
      ;;
  esac
}

# ── Domyślna klasa dla modułu w profilu ──────────────────────
verify_module_severity() {
  local module="$1" profile="$2"
  for entry in "${VERIFY_MODULES[@]}"; do
    local m="${entry%%:*}"
    local rest="${entry#*:}"
    local p="${rest%%:*}"
    local s="${rest#*:}"
    if [ "$m" = "$module" ] && [ "$p" = "$profile" ]; then
      echo "$s"
      return
    fi
  done
  echo "WARNING"
}

# ── Mapowanie nazwy modułu → ścieżka skryptu ────────────────
# Każdy moduł zadeklarowany w VERIFY_MODULES ma odpowiadający skrypt
# w tools/verify/<kategoria>/<nazwa>.sh. To jest JEDYNE miejsce mapowania —
# profiles.sh deklaruje moduły, verify.sh je uruchamia, a SELF-001
# weryfikuje integralność (każdy zadeklarowany moduł MUSI istnieć).
# Rozjazd (FALSE GATE) jest tu eliminowany.
module_script() {
  local module="$1"
  case "$module" in
MID2

    # Wypisz case dla mapowania moduł → skrypt (z sekcji gates:).
    # Wyrównujemy kolumnę `echo` do najdłuższej nazwy modułu, żeby
    # wygenerowany plik miał równe kolumny (kosmetyka, ale czytelność).
    parse_gates | awk -F'|' '
        !seen[$1] { seen[$1]=1; mods[++n]=$1; script[$1]=$2 }
        END {
            # najdłuższa nazwa modułu → szerokość kolumny
            max=0
            for (i=1; i<=n; i++) { len=length(mods[i]); if (len>max) max=len }
            for (i=1; i<=n; i++) {
                m=mods[i]
                pad=max-length(m)
                printf "    %s)%*s echo \"%s\" ;;\n", m, pad+6, "", script[m]
            }
        }
    '

    cat <<'FOOT'
    *)              echo "" ;;
  esac
}
FOOT
} > "$OUT_FILE"

# ── Weryfikacja poprawności składni ────────────────────────────────────────
if ! bash -n "$OUT_FILE"; then
    echo "FATAL: wygenerowany $OUT_FILE ma błąd składni" >&2
    exit 1
fi

echo "OK: wygenerowano $OUT_FILE z $GATES_YAML"
exit 0
