#!/usr/bin/env bash
# ============================================================================
# config.sh — Config Plane resolver (CFG-001: JEDYNY kanał dostępu do configu)
# ============================================================================
# AIGON Production Platform — "najlepszy config na świecie".
#
# Ten plik jest jedynym miejscem, w którym wolno czytać config (CFG-001):
#   * zakaz jq/getenv poza tym plikiem
#   * każda decyzja configu ma trace (snapshot + trace)
#   * każdy błąd = exit 2 (fail-closed, ZERO fallbacków, ZERO cichych defaultów)
#
# Warstwy (L0-L7):
#   L0 defaulty (registry) | L1 org floors | L2 profile | L3 profile override
#   L4 service config | L5 context rules (z diffu) | L6 waivers | L7 kill-switches
#
# 4 prawa configu:
#   1. Tighten zawsze przechodzi (podniesienie progu nie wymaga zgody)
#   2. Relax wymaga waivera (obniżenie poniżej floora = REJECTED bez waivera)
#   3. Wyjątki wygasają (waiver bez expires_at jest nielegalny)
#   4. Każda decyzja ma trace (resolver zapisuje pełny ślad)
#
# Funkcje:
#   config_resolve()          — context → snapshot_id (7 kroków z design doc)
#   config_get()              — key → wartość z przypiętego snapshotu
#   config_trace()            — wypisuje trace dla danego klucza (L0-L5)
#   config_simulate()         — CFG-SIM: symulacja dry-run (GATE_LOST/THRESHOLD_LOOSENED)
#   config_ratchet_update()   — aktualizuje config_ratchet (anti-entropy)
#   config_kill_switch_check()— sprawdza aktywne kill-switches (L7)
#   config_exemption_check()  — sprawdza konstytucję niekonfigurowalnych
# ============================================================================
set -u

# ── Globalne tablice asocjacyjne (wymagane declare -A w bashu) ─────────────
# Stan resolvera między krokami config_resolve.
declare -A CFG_DEFAULT CFG_FLOOR CFG_RATCHET CFG_RELOAD
declare -A CFG_TIGHTEN CFG_RELAX CFG_COMPENSATE
declare -A CFG_EFFECTIVE CFG_TRACE
# Ostatni snapshot_id z config_resolve (dostępny bez subshell — dla config_simulate).
CFG_LAST_SNAPSHOT_ID=""

# ── Ścieżki ────────────────────────────────────────────────────────────────
# Root repo (niezawodne, niezależne od głębokości źródłowania).
CONFIG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CONFIG_REGISTRY="${CONFIG_REGISTRY:-$CONFIG_ROOT/config/canonical/registry.yaml}"
CONFIG_EXEMPTIONS="${CONFIG_EXEMPTIONS:-$CONFIG_ROOT/config/canonical/config_exemptions.yaml}"
CONFIG_PROFILES_DIR="${CONFIG_PROFILES_DIR:-$CONFIG_ROOT/config/profiles}"
CONFIG_SERVICES_DIR="${CONFIG_SERVICES_DIR:-$CONFIG_ROOT/config/services}"

# ── StateStore ─────────────────────────────────────────────────────────────
# Baza canonical state. Override przez VERIFY_STATE_DB (jak w lib.sh).
config_state_db() {
  if [ -n "${VERIFY_STATE_DB:-}" ]; then
    printf '%s\n' "$VERIFY_STATE_DB"
    return 0
  fi
  printf '%s\n' "$CONFIG_ROOT/system/control-plane/state/data/canonical-state.db"
}

# ── Fail-closed helper ─────────────────────────────────────────────────────
# Każdy błąd = exit 2. Zero fallbacków, zero cichych defaultów.
config_fatal() {
  printf 'CONFIG-FATAL: %s\n' "$*" >&2
  exit 2
}

# ── Wymagane narzędzia ─────────────────────────────────────────────────────
config_require_sqlite() {
  command -v sqlite3 >/dev/null 2>&1 || config_fatal "sqlite3 CLI niedostępny — Config Plane wymaga sqlite3"
}

# ── 1. Wczytaj registry (L0) + org floors (L1) ─────────────────────────────
# registry.yaml jest źródłem prawdy (L0 defaulty, L1 floors, L2/L3 profile,
# L5 context rules, L6 waivers, L7 kill_switches, ratchet, reload).
# Jeśli plik nie istnieje → fail-closed (exit 2) z jasnym komunikatem.
#
# Oczekiwana struktura registry.yaml (sekcja gates:):
#   gates:
#     coverage.min_percent:
#       default: 80
#       floor: 60
#       ratchet: true
#       reload: hot
#       doc: "..."
#       owner: platform
#       tier: stable
#
# Parsowanie bez jq/yq — deterministyczny awk dla znanej struktury.
# Wynik zapisuje do globalnych asocjacyjnych tablic:
#   CFG_DEFAULT[key], CFG_FLOOR[key], CFG_RATCHET[key], CFG_RELOAD[key]
config_load_registry() {
  if [ ! -f "$CONFIG_REGISTRY" ]; then
    config_fatal "Brak registry.yaml: $CONFIG_REGISTRY — Config Plane nie może działać bez źródła prawdy (L0/L1). Utwórz config/canonical/registry.yaml."
  fi

  # Wyczyść stan (idempotentność przy wielokrotnym resolve).
  CFG_DEFAULT=()
  CFG_FLOOR=()
  CFG_RATCHET=()
  CFG_RELOAD=()

  local in_gates=0
  local cur_key=""
  local line key val
  while IFS= read -r line; do
    # Sekcja gates: — początek
    if [[ "$line" =~ ^gates:[[:space:]]*$ ]]; then
      in_gates=1
      continue
    fi
    # Koniec sekcji gates (nowa sekcja najwyższego poziomu)
    if [ "$in_gates" -eq 1 ] && [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*$ ]] && ! [[ "$line" =~ ^[[:space:]] ]]; then
      in_gates=0
      continue
    fi
    [ "$in_gates" -eq 1 ] || continue

    # Klucz gate'a (2 spacje wcięcia): "  coverage.min_percent:"
    if [[ "$line" =~ ^[[:space:]]{2}[a-zA-Z0-9_.-]+:[[:space:]]*$ ]]; then
      cur_key="${line%%:*}"
      cur_key="${cur_key#"${cur_key%%[![:space:]]*}"}"   # trim wiodących spacji
      continue
    fi
    [ -n "$cur_key" ] || continue

    # Atrybuty (4 spacje wcięcia): "    default: 80"
    if [[ "$line" =~ ^[[:space:]]{4}([a-zA-Z0-9_.-]+):[[:space:]]*(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      val="${val%%#*}"          # usuń komentarz
      val="${val%"${val##*[![:space:]]}"}"  # trim końcowych spacji
      case "$key" in
        default)  CFG_DEFAULT["$cur_key"]="$val" ;;
        floor)    CFG_FLOOR["$cur_key"]="$val" ;;
        ratchet)  CFG_RATCHET["$cur_key"]="$val" ;;
        reload)   CFG_RELOAD["$cur_key"]="$val" ;;
      esac
    fi
  done < "$CONFIG_REGISTRY"

  if [ "${#CFG_DEFAULT[@]}" -eq 0 ]; then
    config_fatal "registry.yaml nie zawiera żadnych gate'ów w sekcji 'gates:' — Config Plane bez L0 defaultów jest bezużyteczny"
  fi
}

# ── 2. Klasyfikacja kontekstu Z DIFFU (nie z deklaracji) ───────────────────
# Context przyjmowany jako JSON lub zmienne (task_type, files, tier).
# Klasyfikacja opiera się na plikach w diff (files) — nie na deklaracji.
# Wynik: CFG_TASK_TYPE, CFG_TIER, CFG_FILES (tablica).
config_classify_context() {
  local context_json="${1:-}"
  CFG_TASK_TYPE=""
  CFG_TIER=""
  CFG_FILES=()

  # Priorytet: jawny JSON > zmienne środowiskowe.
  if [ -n "$context_json" ] && [ "$context_json" != "-" ]; then
    # Minimalny parser JSON dla znanych pól (task_type, files, tier).
    # Bez jq — deterministyczny sed/awk dla prostej struktury.
    local tt tier
    # Parser obsługuje wartość w cudzysłowie ("tier":"1") ORAZ liczbę bez
    # cudzysłowu ("tier":1). Najpierw próbujemy formy z cudzysłowem, potem
    # bez — pierwszy niepusty wynik wygrywa. Bez jq — deterministyczny sed.
    tt=$(printf '%s' "$context_json" | sed -n 's/.*"task_type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    [ -z "$tt" ] && tt=$(printf '%s' "$context_json" | sed -n 's/.*"task_type"[[:space:]]*:[[:space:]]*\([^",}]*\).*/\1/p')
    tier=$(printf '%s' "$context_json" | sed -n 's/.*"tier"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    [ -z "$tier" ] && tier=$(printf '%s' "$context_json" | sed -n 's/.*"tier"[[:space:]]*:[[:space:]]*\([^",}]*\).*/\1/p')
    [ -n "$tt" ] && CFG_TASK_TYPE="$tt"
    [ -n "$tier" ] && CFG_TIER="$tier"
    # files: tablica JSON ["a","b"] lub ["a", "b"]
    local files_raw
    files_raw=$(printf '%s' "$context_json" | sed -n 's/.*"files"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p')
    if [ -n "$files_raw" ]; then
      local f
      while IFS= read -r f; do
        f="${f//\"/}"
        f="${f#"${f%%[![:space:]]*}"}"
        f="${f%"${f##*[![:space:]]}"}"
        [ -n "$f" ] && CFG_FILES+=("$f")
      done < <(printf '%s\n' "$files_raw" | tr ',' '\n')
    fi
  fi

  # Fallback na zmienne środowiskowe (jeśli JSON nie podał wartości).
  [ -z "$CFG_TASK_TYPE" ] && CFG_TASK_TYPE="${CONFIG_TASK_TYPE:-}"
  [ -z "$CFG_TIER" ] && CFG_TIER="${CONFIG_TIER:-}"

  # Klasyfikacja z diffu: jeśli files zawierają pliki testowe → task_type=test.
  # To jest "z diffu, nie z deklaracji" — deklaracja może kłamać.
  if [ -z "$CFG_TASK_TYPE" ] && [ "${#CFG_FILES[@]}" -gt 0 ]; then
    local f
    for f in "${CFG_FILES[@]}"; do
      case "$f" in
        *test*|*spec*|*_test.go|*.test.ts|*.test.js|*.spec.ts|*.spec.js)
          CFG_TASK_TYPE="test"
          break
          ;;
      esac
    done
  fi
  [ -z "$CFG_TASK_TYPE" ] && CFG_TASK_TYPE="default"

  # Tier: domyślnie 0 (brak deklaracji = najniższy, najbezpieczniejszy).
  [ -z "$CFG_TIER" ] && CFG_TIER="0"
}

# ── 3. Dopasuj context rules (L5) → profil + tighten/relax + kompensacje ───
# Context rules w registry.yaml (sekcja context_rules:):
#   context_rules:
#     - match:
#         task_type: test
#         files: ["*_test.go"]
#       profile: full
#       tighten:
#         coverage.min_percent: 90
#       relax:
#         coverage.min_percent: 70
#       compensate:
#         coverage.min_percent: security.sast.max_critical
#
# Reguła jest stosowana TYLKO gdy pasuje do kontekstu (task_type + files).
# Parser jest odporny na wcięcia (dowolna liczba spacji) — nie zakłada
# sztywnej indentacji YAML.
# Wynik: CFG_PROFILE, CFG_TIGHTEN (tablica key=value), CFG_RELAX, CFG_COMPENSATE.
config_apply_context_rules() {
  CFG_PROFILE=""
  CFG_TIGHTEN=()
  CFG_RELAX=()
  CFG_COMPENSATE=()

  [ -f "$CONFIG_REGISTRY" ] || return 0

  local in_rules=0
  local in_rule=0
  local in_tighten=0 in_relax=0 in_compensate=0
  local in_gates=0 in_compensations=0
  local cur_match_task="" cur_match_files=""
  local cur_profile=""
  local -A cur_tighten cur_relax cur_compensate
  # Bogata gramatyka applies_when: lista warunków {field, op, value} (AND).
  # Przechowujemy je jako tablicę stringów "field|op|value" (value może być
  # listą oddzieloną przecinkami dla op=in).
  local -a cur_conditions=()
  local line key val

  # ── Pomocnicze: dopasowanie pojedynczego warunku applies_when ────────────
  # Warunek: { field: <task_type|files|tier>, op: <eq|ne|in|match|glob>,
  #            value: <wartość lub lista> }
  # Zwraca 0 = warunek spełniony, 1 = nie.
  config_condition_matches() {
    local field="$1" op="$2" value="$3"
    case "$field" in
      task_type)
        case "$op" in
          eq) [ "$value" = "$CFG_TASK_TYPE" ] ;;
          ne) [ "$value" != "$CFG_TASK_TYPE" ] ;;
          in)
            local v
            while IFS=',' read -r v; do
              v="${v//\"/}"; v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
              [ -n "$v" ] && [ "$v" = "$CFG_TASK_TYPE" ] && return 0
            done <<< "$value"
            return 1
            ;;
          *) return 1 ;;
        esac
        ;;
      tier)
        case "$op" in
          eq) [ "$value" = "$CFG_TIER" ] ;;
          ne) [ "$value" != "$CFG_TIER" ] ;;
          in)
            local v
            while IFS=',' read -r v; do
              v="${v//\"/}"; v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
              [ -n "$v" ] && [ "$v" = "$CFG_TIER" ] && return 0
            done <<< "$value"
            return 1
            ;;
          *) return 1 ;;
        esac
        ;;
      files)
        # files używa glob/match na ścieżce pliku. Pasuje jeśli którykolwiek
        # plik z CFG_FILES pasuje do globu.
        # Obsługuje: ** (dowolna głębokość), * (dowolny ciąg), ? (jeden znak),
        # oraz ekspansję klamrową {a,b,c} → (a|b|c) (np. "**/*.{ts,go,rs}").
        local glob f
        local any=0
        for f in "${CFG_FILES[@]:-}"; do
          [ -n "$f" ] || continue
          glob="${value//\"/}"
          glob="${glob#"${glob%%[![:space:]]*}"}"
          glob="${glob%"${glob##*[![:space:]]}"}"
          [ -n "$glob" ] || continue
          # Konwersja globu na regex: ** → .*, * → [^/]*, ? → [^/],
          # {a,b,c} → (a|b|c). Reszta znaków literał (escape).
          local re="" ch i
          i=0
          while [ "$i" -lt "${#glob}" ]; do
            ch="${glob:$i:1}"
            case "$ch" in
              '*')
                if [ "$i" -lt $(( ${#glob} - 1 )) ] && [ "${glob:$((i+1)):1}" = "*" ]; then
                  re+=".*"; i=$((i+2)); continue
                else
                  re+="[^/]*"; i=$((i+1)); continue
                fi
                ;;
              '?') re+="[^/]"; i=$((i+1)); continue ;;
              '{')
                # Znajdź zamykającą klamrę i rozwiń {a,b,c} → (a|b|c).
                local close=-1 j
                for (( j=i+1; j<${#glob}; j++ )); do
                  [ "${glob:$j:1}" = "}" ] && { close=$j; break; }
                done
                if [ "$close" -gt "$i" ]; then
                  local inner="${glob:$((i+1)):$((close-i-1))}"
                  re+="(${inner//,/|})"
                  i=$((close+1)); continue
                else
                  re+="\{"; i=$((i+1)); continue
                fi
                ;;
              '.') re+="\."; i=$((i+1)); continue ;;
              '[') re+="\["; i=$((i+1)); continue ;;
              ']') re+="\]"; i=$((i+1)); continue ;;
              '(') re+="\("; i=$((i+1)); continue ;;
              ')') re+="\)"; i=$((i+1)); continue ;;
              '+') re+="\+"; i=$((i+1)); continue ;;
              '^') re+="\^"; i=$((i+1)); continue ;;
              '$') re+="\$"; i=$((i+1)); continue ;;
              '|') re+="\|"; i=$((i+1)); continue ;;
              *) re+="$ch"; i=$((i+1)); continue ;;
            esac
          done
          if [[ "$f" =~ ^$re$ ]]; then
            any=1
            break
          fi
        done
        [ "$any" -eq 1 ]
        ;;
      *) return 1 ;;
    esac
  }

  # ── Zastosuj bieżącą regułę, jeśli pasuje do kontekstu ───────────────────
  # Obsługuje OBA formaty:
  #   - match: (prosty) — task_type + files
  #   - applies_when: (bogaty) — lista warunków {field, op, value}, WSZYSTKIE
  #     muszą być spełnione (AND).
  # Reguła bez żadnego warunku pasuje do wszystkiego (globalna).
  config_apply_rule() {
    local matched=1

    # Bogata gramatyka applies_when (jeśli zdefiniowano warunki).
    if [ "${#cur_conditions[@]}" -gt 0 ]; then
      local cond
      for cond in "${cur_conditions[@]}"; do
        local cfield cop cvalue
        cfield="${cond%%|*}"; cvalue="${cond##*|}"
        cop="${cond#*|}"; cop="${cop%%|*}"
        if ! config_condition_matches "$cfield" "$cop" "$cvalue"; then
          matched=0
          break
        fi
      done
    fi

    # Prosta gramatyka match: (kompatybilność wsteczna).
    if [ "$matched" -eq 1 ] && [ -n "$cur_match_task" ] && [ "$cur_match_task" != "$CFG_TASK_TYPE" ]; then
      matched=0
    fi
    if [ "$matched" -eq 1 ] && [ -n "$cur_match_files" ]; then
      # files: lista globów oddzielonych przecinkami. Pasuje jeśli którykolwiek
      # plik z CFG_FILES pasuje do któregokolwiek globu.
      local glob f
      local any=0
      for f in "${CFG_FILES[@]:-}"; do
        [ -n "$f" ] || continue
        while IFS= read -r glob; do
          glob="${glob//\"/}"
          glob="${glob#"${glob%%[![:space:]]*}"}"
          glob="${glob%"${glob##*[![:space:]]}"}"
          [ -n "$glob" ] || continue
          if [[ "$f" == $glob ]]; then
            any=1
            break
          fi
        done < <(printf '%s' "$cur_match_files" | tr ',' '\n')
        [ "$any" -eq 1 ] && break
      done
      [ "$any" -eq 1 ] || matched=0
    fi

    if [ "$matched" -eq 1 ]; then
      [ -n "$cur_profile" ] && CFG_PROFILE="$cur_profile"
      local k
      for k in "${!cur_tighten[@]}"; do CFG_TIGHTEN["$k"]="${cur_tighten[$k]}"; done
      for k in "${!cur_relax[@]}"; do CFG_RELAX["$k"]="${cur_relax[$k]}"; done
      for k in "${!cur_compensate[@]}"; do CFG_COMPENSATE["$k"]="${cur_compensate[$k]}"; done
    fi
  }

  # ── Reset stanu bieżącej reguły ──────────────────────────────────────────
  config_reset_rule() {
    cur_match_task=""
    cur_match_files=""
    cur_profile=""
    cur_tighten=(); cur_relax=(); cur_compensate=()
    cur_conditions=()
    in_tighten=0; in_relax=0; in_compensate=0
    in_gates=0; in_compensations=0
  }

  while IFS= read -r line; do
    if [[ "$line" =~ ^context_rules:[[:space:]]*$ ]]; then
      in_rules=1
      continue
    fi
    [ "$in_rules" -eq 1 ] || continue
    # Koniec sekcji context_rules (nowa sekcja najwyższego poziomu).
    if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*$ ]] && ! [[ "$line" =~ ^[[:space:]] ]]; then
      if [ "$in_rule" -eq 1 ]; then config_apply_rule; in_rule=0; fi
      in_rules=0
      continue
    fi

    # Nowa reguła: "  - match:" lub "  - id: ..." (dowolne wcięcie).
    # Bogaty format zaczyna się od "  - id:"; prosty od "  - match:".
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*match:[[:space:]]*$ ]]; then
      if [ "$in_rule" -eq 1 ]; then config_apply_rule; fi
      in_rule=1
      config_reset_rule
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id:[[:space:]]*\"?([^\"[:space:]]*)\"?[[:space:]]*$ ]]; then
      if [ "$in_rule" -eq 1 ]; then config_apply_rule; fi
      in_rule=1
      config_reset_rule
      # id jest metadata — ignorowane przez resolver.
      continue
    fi
    [ "$in_rule" -eq 1 ] || continue

    # ── Bogata gramatyka applies_when ──────────────────────────────────────
    # "    applies_when:" — początek listy warunków.
    if [[ "$line" =~ ^[[:space:]]+applies_when:[[:space:]]*$ ]]; then
      in_gates=0; in_compensations=0; in_tighten=0; in_relax=0; in_compensate=0
      continue
    fi
    # Warunek: "      - { field: task_type, op: eq, value: hotfix }"
    # lub "      - { field: files, op: glob, value: "**/migrations/**" }"
    if [[ "$line" =~ ^[[:space:]]+-[[:space:]]*\{[[:space:]]*field:[[:space:]]*\"?([a-zA-Z_]+)\"?[[:space:]]*,[[:space:]]*op:[[:space:]]*\"?([a-zA-Z]+)\"?[[:space:]]*,[[:space:]]*value:[[:space:]]*(.*)\}[[:space:]]*$ ]]; then
      local cfield="${BASH_REMATCH[1]}"
      local cop="${BASH_REMATCH[2]}"
      local cvalue="${BASH_REMATCH[3]}"
      # value może być: "hotfix", 1, [1, 2], "**/migrations/**"
      cvalue="${cvalue//\"/}"
      cvalue="${cvalue#"${cvalue%%[![:space:]]*}"}"
      cvalue="${cvalue%"${cvalue##*[![:space:]]}"}"
      # Lista [a, b] → "a,b" (dla op=in).
      if [[ "$cvalue" =~ ^\[(.*)\]$ ]]; then
        cvalue="${BASH_REMATCH[1]}"
        cvalue="${cvalue// /}"
      fi
      cur_conditions+=("$cfield|$cop|$cvalue")
      continue
    fi

    # ── match.task_type / match.files (prosty format, dowolne wcięcie) ─────
    if [[ "$line" =~ ^[[:space:]]+task_type:[[:space:]]*\"?([^\"[:space:]]*)\"?[[:space:]]*$ ]]; then
      cur_match_task="${BASH_REMATCH[1]}"
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]+files:[[:space:]]*\[(.*)\]$ ]]; then
      cur_match_files="${BASH_REMATCH[1]}"
      continue
    fi

    # profile: (dowolne wcięcie).
    if [[ "$line" =~ ^[[:space:]]+profile:[[:space:]]*\"?([^\"[:space:]]*)\"?[[:space:]]*$ ]]; then
      cur_profile="${BASH_REMATCH[1]}"
      continue
    fi

    # ── Bogata gramatyka gates: (mapa key: {tighten|relax}) ────────────────
    # "    gates:" — początek sekcji.
    if [[ "$line" =~ ^[[:space:]]+gates:[[:space:]]*$ ]]; then
      in_gates=1; in_compensations=0; in_tighten=0; in_relax=0; in_compensate=0
      continue
    fi
    # Wpis w gates: "      structure.readme.required_sections: { tighten: 3 }"
    if [ "$in_gates" -eq 1 ] && [[ "$line" =~ ^[[:space:]]+([a-zA-Z0-9_.-]+):[[:space:]]*\{[[:space:]]*(tighten|relax):[[:space:]]*\"?([^\"[:space:]}]*)\"?[[:space:]]*\}[[:space:]]*$ ]]; then
      key="${BASH_REMATCH[1]}"
      local gop="${BASH_REMATCH[2]}"
      val="${BASH_REMATCH[3]}"
      if [ "$gop" = "tighten" ]; then
        cur_tighten["$key"]="$val"
      else
        cur_relax["$key"]="$val"
      fi
      continue
    fi

    # ── Bogata gramatyka compensations: (lista map key: {tighten}) ─────────
    # "    compensations:" — początek sekcji.
    if [[ "$line" =~ ^[[:space:]]+compensations:[[:space:]]*$ ]]; then
      in_compensations=1; in_gates=0; in_tighten=0; in_relax=0; in_compensate=0
      continue
    fi
    # Wpis w compensations: "      - security.sast.max_critical: { tighten: 0 }"
    if [ "$in_compensations" -eq 1 ] && [[ "$line" =~ ^[[:space:]]+-[[:space:]]*([a-zA-Z0-9_.-]+):[[:space:]]*\{[[:space:]]*tighten:[[:space:]]*\"?([^\"[:space:]}]*)\"?[[:space:]]*\}[[:space:]]*$ ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      cur_compensate["$key"]="$val"
      continue
    fi

    # ── Prosty format: tighten: / relax: / compensate: (sekcje) ────────────
    if [[ "$line" =~ ^[[:space:]]+tighten:[[:space:]]*$ ]]; then in_tighten=1; in_relax=0; in_compensate=0; in_gates=0; in_compensations=0; continue; fi
    if [[ "$line" =~ ^[[:space:]]+relax:[[:space:]]*$ ]]; then in_relax=1; in_tighten=0; in_compensate=0; in_gates=0; in_compensations=0; continue; fi
    if [[ "$line" =~ ^[[:space:]]+compensate:[[:space:]]*$ ]]; then in_compensate=1; in_tighten=0; in_relax=0; in_gates=0; in_compensations=0; continue; fi
    # Wpisy w prostych sekcjach: "      coverage.min_percent: 90" (dowolne wcięcie).
    if [[ "$line" =~ ^[[:space:]]+([a-zA-Z0-9_.-]+):[[:space:]]*\"?([^\"[:space:]]*)\"?[[:space:]]*$ ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      if [ "$in_tighten" -eq 1 ]; then
        cur_tighten["$key"]="$val"
      elif [ "$in_relax" -eq 1 ]; then
        cur_relax["$key"]="$val"
      elif [ "$in_compensate" -eq 1 ]; then
        cur_compensate["$key"]="$val"
      fi
      continue
    fi
  done < "$CONFIG_REGISTRY"

  # Zastosuj ostatnią regułę (jeśli sekcja nie zakończyła się nową sekcją).
  if [ "$in_rule" -eq 1 ]; then config_apply_rule; fi

  [ -z "$CFG_PROFILE" ] && CFG_PROFILE="full"
}

# ── 4. Nałóż L2→L3→L4→L5 z egzekwowaniem floorów ───────────────────────────
# Dla każdego klucza: start od L0 default, nałóż profile (L2/L3), service (L4),
# context rules (L5). Relax poniżej floora bez waivera = REJECTED (w trace).
# Wynik: CFG_EFFECTIVE[key]=value, CFG_TRACE[key]="JSON trace".
config_apply_layers() {
  local service_id="${1:-}"
  CFG_EFFECTIVE=()
  CFG_TRACE=()

  local key default floor ratchet
  for key in "${!CFG_DEFAULT[@]}"; do
    default="${CFG_DEFAULT[$key]}"
    floor="${CFG_FLOOR[$key]:-}"
    ratchet="${CFG_RATCHET[$key]:-false}"

    local value="$default"
    local trace="[{\"layer\":\"L0 default\",\"value\":\"$default\"}"
    local floor_dir
    floor_dir="$(config_floor_direction "$key")"
    if [ -n "$floor" ]; then
      if [ "$floor_dir" = "max" ]; then
        trace+=",{\"layer\":\"L1 floor\",\"constraint\":\"<=$floor\"}"
      else
        trace+=",{\"layer\":\"L1 floor\",\"constraint\":\">=$floor\"}"
      fi
    fi

    # L2/L3 profile override (config/profiles/<profile>.yaml)
    local profile_val
    profile_val="$(config_profile_value "$CFG_PROFILE" "$key")"
    if [ -n "$profile_val" ]; then
      value="$profile_val"
      trace+=",{\"layer\":\"L2/L3 profile\",\"value\":\"$profile_val\"}"
    fi

    # L4 service config (config/services/<service_id>.yaml)
    local service_val
    service_val="$(config_service_value "$service_id" "$key")"
    if [ -n "$service_val" ]; then
      value="$service_val"
      trace+=",{\"layer\":\"L4 service\",\"value\":\"$service_val\"}"
    fi

    # L5 context rules: tighten / relax
    local tighten_val="${CFG_TIGHTEN[$key]:-}"
    local relax_val="${CFG_RELAX[$key]:-}"
    if [ -n "$tighten_val" ]; then
      value="$tighten_val"
      trace+=",{\"layer\":\"L5 hotfix\",\"value\":\"$tighten_val\",\"result\":\"WIN (tighten)\"}"
    elif [ -n "$relax_val" ]; then
      # Relax wymaga waivera. Bez waivera = REJECTED (zapisane w trace).
      if config_has_waiver "$key" "$relax_val"; then
        value="$relax_val"
        trace+=",{\"layer\":\"L5 hotfix\",\"value\":\"$relax_val\",\"result\":\"RELAX (waiver)\"}"
      else
        trace+=",{\"layer\":\"L5 hotfix\",\"value\":\"$relax_val\",\"result\":\"REJECTED (relax bez waivera)\"}"
        # Fail-closed: relax bez waivera = REJECTED. Wartość NIE jest obniżana.
      fi
    fi

    # Egzekwowanie floora (L1): kierunek zależy od typu klucza.
    #   min_*: floor = dolny limit (value < floor → REJECTED).
    #   max_*: floor = górny limit (value > floor → REJECTED).
    if [ -n "$floor" ] && config_is_numeric "$value" && config_is_numeric "$floor"; then
      if { [ "$floor_dir" = "max" ] && config_num_gt "$value" "$floor"; } || \
         { [ "$floor_dir" = "min" ] && config_num_lt "$value" "$floor"; }; then
        # Poza floor'em — wymaga waivera.
        if ! config_has_waiver "$key" "$value"; then
          trace+=",{\"layer\":\"L1 floor\",\"result\":\"REJECTED (poza floor'em bez waivera)\"}"
          value="$floor"
        fi
      fi
    fi

    # Ratchet (anti-entropy): per-serwis wartość może TYLKO się zaostrzać.
    #   min_*: może tylko rosnąć (value < achieved → REJECTED).
    #   max_*: może tylko maleć (value > achieved → REJECTED).
    if [ "$ratchet" = "true" ] && [ -n "$service_id" ]; then
      local achieved
      achieved="$(config_ratchet_get "$service_id" "$key")"
      if [ -n "$achieved" ] && config_is_numeric "$achieved" && config_is_numeric "$value"; then
        local ratchet_violated=false
        if { [ "$floor_dir" = "max" ] && config_num_gt "$value" "$achieved"; } || \
           { [ "$floor_dir" = "min" ] && config_num_lt "$value" "$achieved"; }; then
          ratchet_violated=true
        fi
        if [ "$ratchet_violated" = "true" ]; then
          if ! config_has_waiver "$key" "$value"; then
            trace+=",{\"layer\":\"ratchet\",\"result\":\"REJECTED (poza achieved=$achieved bez waivera)\"}"
            value="$achieved"
          fi
        fi
      fi
    fi

    trace+="]"
    CFG_EFFECTIVE["$key"]="$value"
    CFG_TRACE["$key"]="$trace"
  done
}

# ── L2/L3 profile value ────────────────────────────────────────────────────
# config/profiles/<profile>.yaml — sekcja gates: z wartościami.
config_profile_value() {
  local profile="$1" key="$2"
  local f="$CONFIG_PROFILES_DIR/$profile.yaml"
  [ -f "$f" ] || return 0
  local val
  val=$(awk -v k="$key" '
    /^gates:/ { in_gates=1; next }
    in_gates && /^[a-zA-Z0-9_.-]+:/ && !/^[[:space:]]/ { in_gates=0 }
    in_gates && $0 ~ "^  " k ":" {
      sub(/^[[:space:]]*[^:]+:[[:space:]]*/, ""); print; exit
    }
  ' "$f")
  printf '%s\n' "$val"
}

# ── L4 service value ───────────────────────────────────────────────────────
# config/services/<service_id>.yaml — sekcja gates: z wartościami.
config_service_value() {
  local service_id="$1" key="$2"
  [ -n "$service_id" ] || return 0
  local f="$CONFIG_SERVICES_DIR/$service_id.yaml"
  [ -f "$f" ] || return 0
  local val
  val=$(awk -v k="$key" '
    /^gates:/ { in_gates=1; next }
    in_gates && /^[a-zA-Z0-9_.-]+:/ && !/^[[:space:]]/ { in_gates=0 }
    in_gates && $0 ~ "^  " k ":" {
      sub(/^[[:space:]]*[^:]+:[[:space:]]*/, ""); print; exit
    }
  ' "$f")
  printf '%s\n' "$val"
}

# ── 5. Aktywne waivers (L6) ────────────────────────────────────────────────
# Waivers w registry.yaml (sekcja waivers:) lub w StateStore.
# Wygasły (expires_at <= now) = nie istnieje.
config_has_waiver() {
  local key="$1" value="$2"
  local now
  now="$(date +%Y-%m-%d)"

  # Waivers z registry.yaml (sekcja waivers:)
  # Format: lista map `- id: ...` z polami `key:` i `expires_at:` (4-space indent).
  if [ -f "$CONFIG_REGISTRY" ]; then
    local in_w=0 cur_key="" cur_exp=""
    local line
    while IFS= read -r line; do
      if [[ "$line" =~ ^waivers:[[:space:]]*$ ]]; then in_w=1; continue; fi
      [ "$in_w" -eq 1 ] || continue
      # Koniec sekcji waivers: nowa sekcja top-level (bez wcięcia).
      if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*$ ]] && ! [[ "$line" =~ ^[[:space:]] ]]; then in_w=0; continue; fi
      # Nowy wpis waivera (`- id:` lub `- key:`) — reset stanu bieżącego.
      if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]*id:[[:space:]]*\"?[^\"[:space:]]*\"?[[:space:]]*$ ]] || \
         [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]*key:[[:space:]]*\"?[^\"[:space:]]*\"?[[:space:]]*$ ]]; then
        cur_key=""; cur_exp=""; continue
      fi
      # Pole `key:` (4-space indent) — zapamiętaj klucz bieżącego waivera.
      if [[ "$line" =~ ^[[:space:]]{4}key:[[:space:]]*\"?([^\"[:space:]]*)\"?[[:space:]]*$ ]]; then
        cur_key="${BASH_REMATCH[1]}"; continue
      fi
      # Pole `expires_at:` (4-space indent) — jeśli klucz pasuje i nie wygasł → waiver aktywny.
      if [[ "$line" =~ ^[[:space:]]{4}expires_at:[[:space:]]*\"?([^\"[:space:]]*)\"?[[:space:]]*$ ]]; then
        cur_exp="${BASH_REMATCH[1]}"
        if [ "$cur_key" = "$key" ] && [ -n "$cur_exp" ] && [ "$cur_exp" \> "$now" ]; then
          return 0
        fi
      fi
    done < "$CONFIG_REGISTRY"
  fi

  # Waivers z StateStore (tabela config_waivers, jeśli istnieje).
  local db
  db="$(config_state_db)"
  if [ -f "$db" ]; then
    local has_tbl
    has_tbl=$(sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table' AND name='config_waivers';" 2>/dev/null)
    if [ -n "$has_tbl" ]; then
      local cnt
      cnt=$(sqlite3 "$db" "SELECT COUNT(*) FROM config_waivers WHERE key='$key' AND expires_at > '$now';" 2>/dev/null)
      [ "$cnt" -gt 0 ] 2>/dev/null && return 0
    fi
  fi

  return 1
}

# ── 6. Walidacja finalna: schema + inwarianty + kompletność kompensacji ────
config_validate_final() {
  # Inwariant: każdy klucz z L0 default musi mieć wartość effective.
  local key
  for key in "${!CFG_DEFAULT[@]}"; do
    if [ -z "${CFG_EFFECTIVE[$key]:-}" ]; then
      config_fatal "Walidacja finalna: klucz '$key' nie ma wartości effective — brak kompletności"
    fi
  done

  # Kompletność kompensacji: każdy relax musi mieć kompensację (jeśli zdefiniowano).
  # Kompensacja to tighten INNEGO klucza (np. relax max_outdated + tighten
  # max_critical). Sprawdzamy, czy dla każdego relaxu istnieje CO NAJMNIEJ
  # jedna kompensacja (na dowolnym kluczu).
  if [ "${#CFG_RELAX[@]}" -gt 0 ] && [ "${#CFG_COMPENSATE[@]}" -eq 0 ]; then
    config_fatal "Walidacja finalna: relax bez kompensacji — naruszenie inwariantu kompletności"
  fi

  # Inwariant: wartość nie może być pusta (zero cichych defaultów).
  for key in "${!CFG_EFFECTIVE[@]}"; do
    if [ -z "${CFG_EFFECTIVE[$key]}" ]; then
      config_fatal "Walidacja finalna: klucz '$key' ma pustą wartość effective"
    fi
  done
}

# ── 7. Zmaterializuj → hash → INSERT snapshot → zwróć id ───────────────────
config_materialize_snapshot() {
  local service_id="${1:-}"
  local git_sha
  git_sha="$(git -C "$CONFIG_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")"

  # Zmaterializowany effective config jako JSON.
  local effective_json="{"
  local first=1 key
  for key in "${!CFG_EFFECTIVE[@]}"; do
    [ "$first" -eq 1 ] || effective_json+=","
    effective_json+="\"$key\":\"${CFG_EFFECTIVE[$key]}\""
    first=0
  done
  effective_json+="}"

  # Hash zmaterializowanego configu (deterministyczny).
  local hash
  hash="$(printf '%s' "$effective_json" | sha256sum | awk '{print $1}')"

  local db
  db="$(config_state_db)"
  config_require_sqlite

  # Fail-closed: baza musi istnieć i mieć tabelę config_snapshots.
  if [ ! -f "$db" ]; then
    config_fatal "Brak bazy StateStore: $db — nie można zapisać snapshotu configu. Uruchom state.sh init && state.sh migrate."
  fi
  local has_tbl
  has_tbl=$(sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table' AND name='config_snapshots';" 2>/dev/null)
  if [ -z "$has_tbl" ]; then
    config_fatal "Brak tabeli config_snapshots w StateStore — migracja 0006 nie została zastosowana. Uruchom state.sh migrate."
  fi

  # INSERT snapshot (idempotentny po hash — UNIQUE).
  local sid
  sid="cfg-${hash:0:8}"
  sqlite3 "$db" "INSERT OR IGNORE INTO config_snapshots (hash, git_sha, waiver_set_version, effective_json) VALUES ('$hash', '$git_sha', 0, '$effective_json');" 2>/dev/null \
    || config_fatal "INSERT snapshot configu NIE powiódł się (hash=$hash)"

  # Zwróć snapshot_id (istniejący lub nowo wstawiony).
  local existing
  existing=$(sqlite3 "$db" "SELECT id FROM config_snapshots WHERE hash='$hash';" 2>/dev/null)
  [ -n "$existing" ] || config_fatal "Snapshot configu nie znaleziony po INSERT (hash=$hash)"
  printf '%s\n' "$existing"
}

# ── config_resolve: 7 kroków z design doc ──────────────────────────────────
# Użycie: config_resolve [context_json] [service_id]
#   context_json — JSON z task_type/files/tier (opcjonalnie "-" dla braku)
#   service_id   — identyfikator serwisu (opcjonalnie)
# Zwraca snapshot_id na stdout.
config_resolve() {
  local context_json="${1:--}"
  local service_id="${2:-}"

  # Krok 1: wczytaj registry (L0) + org floors (L1)
  config_load_registry

  # Krok 2: klasyfikacja kontekstu Z DIFFU
  config_classify_context "$context_json"

  # Krok 3: dopasuj context rules (L5)
  config_apply_context_rules

  # Krok 4: nałóż L2→L3→L4→L5 z egzekwowaniem floorów
  config_apply_layers "$service_id"

  # Krok 5: aktywne waivers (L6) — już uwzględnione w config_apply_layers
  #         (config_has_waiver sprawdza expires_at > now)

  # Krok 6: walidacja finalna
  config_validate_final

  # Krok 7: zmaterializuj → hash → INSERT snapshot → zwróć id
  # Zapisz snapshot_id także w globalnej zmiennej (dostępnej bez subshell),
  # aby config_simulate mógł porównać CFG_EFFECTIVE po resolve w bieżącym procesie.
  CFG_LAST_SNAPSHOT_ID="$(config_materialize_snapshot "$service_id")"
  printf '%s\n' "$CFG_LAST_SNAPSHOT_ID"
}

# ── config_get: key → wartość z przypiętego snapshotu ──────────────────────
# Klucz nieznany = FATAL (nie default!). Zero cichych defaultów.
# Użycie: config_get <snapshot_id> <key>
config_get() {
  local snapshot_id="$1" key="$2"
  local db
  db="$(config_state_db)"
  config_require_sqlite

  [ -f "$db" ] || config_fatal "Brak bazy StateStore: $db — config_get wymaga snapshotu"
  local has_tbl
  has_tbl=$(sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table' AND name='config_snapshots';" 2>/dev/null)
  [ -n "$has_tbl" ] || config_fatal "Brak tabeli config_snapshots w StateStore — migracja 0006 nie została zastosowana"

  # Pobierz effective_json dla snapshotu.
  local eff
  eff=$(sqlite3 "$db" "SELECT effective_json FROM config_snapshots WHERE id='$snapshot_id';" 2>/dev/null)
  [ -n "$eff" ] || config_fatal "Snapshot '$snapshot_id' nie istnieje w config_snapshots"

  # Wyciągnij wartość klucza z JSON. Klucz nieznany = FATAL (nie default!).
  local val
  val=$(printf '%s' "$eff" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p")
  if [ -z "$val" ]; then
    # Sprawdź czy klucz w ogóle istnieje w snapshotcie (rozróżnij "pusty" od "nieznany").
    if printf '%s' "$eff" | grep -q "\"$key\""; then
      printf '%s\n' "$val"
      return 0
    fi
    config_fatal "config_get: nieznany klucz '$key' w snapshotcie '$snapshot_id' — brak cichego defaultu"
  fi
  printf '%s\n' "$val"
}

# ── config_trace: wypisuje trace dla danego klucza (L0-L5) ─────────────────
# Użycie: config_trace <snapshot_id> <key>
config_trace() {
  local snapshot_id="$1" key="$2"
  local db
  db="$(config_state_db)"
  config_require_sqlite

  [ -f "$db" ] || config_fatal "Brak bazy StateStore: $db — config_trace wymaga snapshotu"
  local has_tbl
  has_tbl=$(sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table' AND name='config_snapshots';" 2>/dev/null)
  [ -n "$has_tbl" ] || config_fatal "Brak tabeli config_snapshots w StateStore — migracja 0006 nie została zastosowana"

  local eff
  eff=$(sqlite3 "$db" "SELECT effective_json FROM config_snapshots WHERE id='$snapshot_id';" 2>/dev/null)
  [ -n "$eff" ] || config_fatal "Snapshot '$snapshot_id' nie istnieje w config_snapshots"

  # Trace jest przechowywany w CFG_TRACE (w pamięci bieżącego procesu).
  # Dla snapshotu z bazy wypisujemy wartość + ślad warstw z effective_json.
  local val
  val=$(printf '%s' "$eff" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p")
  if [ -z "$val" ] && ! printf '%s' "$eff" | grep -q "\"$key\""; then
    config_fatal "config_trace: nieznany klucz '$key' w snapshotcie '$snapshot_id'"
  fi
  printf 'key=%s value=%s\n' "$key" "$val"
  # Jeśli trace jest dostępny w pamięci (bieżący resolve), wypisz go.
  if [ -n "${CFG_TRACE[$key]:-}" ]; then
    printf 'trace=%s\n' "${CFG_TRACE[$key]}"
  else
    printf 'trace=(brak w pamięci — trace pełny dostępny w bieżącym resolve)\n'
  fi
}

# ── Pomocnicze: porównania numeryczne ──────────────────────────────────────
config_is_numeric() {
  [[ "$1" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]
}

config_num_lt() {
  # Zwraca 0 jeśli $1 < $2 (liczby zmiennoprzecinkowe).
  awk -v a="$1" -v b="$2" 'BEGIN { exit !(a < b) }'
}

config_num_gt() {
  # Zwraca 0 jeśli $1 > $2 (liczby zmiennoprzecinkowe).
  awk -v a="$1" -v b="$2" 'BEGIN { exit !(a > b) }'
}

# ── Kierunek floora dla klucza ─────────────────────────────────────────────
# Floor jest "minimalnym progiem" (design doc) dla kluczy min_* — dolny limit
# (value < floor → REJECTED). Dla kluczy max_* floor jest GÓRNYM limitem
# (value > floor → REJECTED), bo niższa wartość = ostrzejsza reguła.
# Klucze są w formie "domena.pod.max_*" (np. security.sast.max_high), więc
# segment max_/min_ może wystąpić po kropce, nie tylko na początku klucza.
# Użycie: config_floor_direction <key> → "max" | "min"
config_floor_direction() {
  case "$1" in
    max_*|*.max_*) printf 'max\n' ;;
    *)             printf 'min\n' ;;
  esac
}

# ── Ratchet: pobierz osiągniętą wartość per serwis/klucz ───────────────────
# config_ratchet_get <service_id> <key> → achieved_value (lub puste)
config_ratchet_get() {
  local service_id="$1" key="$2"
  local db
  db="$(config_state_db)"
  [ -f "$db" ] || return 0
  local has_tbl
  has_tbl=$(sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table' AND name='config_ratchet';" 2>/dev/null)
  [ -n "$has_tbl" ] || return 0
  sqlite3 "$db" "SELECT achieved_value FROM config_ratchet WHERE service_id='$service_id' AND key='$key';" 2>/dev/null
}

# ── config_ratchet_update: aktualizuje config_ratchet (anti-entropy) ───────
# Nowy config nie może się poluzować bez waivera:
#   min_*: nie może obniżyć wartości (value < cur → REJECTED).
#   max_*: nie może podnieść wartości (value > cur → REJECTED).
# Użycie: config_ratchet_update <service_id> <key> <achieved_value>
config_ratchet_update() {
  local service_id="$1" key="$2" achieved="$3"
  local db
  db="$(config_state_db)"
  config_require_sqlite

  [ -f "$db" ] || config_fatal "Brak bazy StateStore: $db — config_ratchet_update wymaga bazy"
  local has_tbl
  has_tbl=$(sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table' AND name='config_ratchet';" 2>/dev/null)
  [ -n "$has_tbl" ] || config_fatal "Brak tabeli config_ratchet w StateStore — migracja 0006 nie została zastosowana"

  # Pobierz obecną achieved_value.
  local cur
  cur=$(sqlite3 "$db" "SELECT achieved_value FROM config_ratchet WHERE service_id='$service_id' AND key='$key';" 2>/dev/null)

  local floor_dir
  floor_dir="$(config_floor_direction "$key")"
  if [ -n "$cur" ] && config_is_numeric "$cur" && config_is_numeric "$achieved"; then
    local loosened=false
    if { [ "$floor_dir" = "max" ] && config_num_gt "$achieved" "$cur"; } || \
       { [ "$floor_dir" = "min" ] && config_num_lt "$achieved" "$cur"; }; then
      loosened=true
    fi
    if [ "$loosened" = "true" ]; then
      # Próba poluzowania — wymaga waivera.
      if ! config_has_waiver "$key" "$achieved"; then
        config_fatal "config_ratchet_update: próba poluzowania achieved dla '$service_id/$key' z '$cur' na '$achieved' bez waivera — REJECTED"
      fi
    fi
  fi

  # UPSERT (INSERT OR REPLACE).
  sqlite3 "$db" "INSERT OR REPLACE INTO config_ratchet (service_id, key, achieved_value, updated_at) VALUES ('$service_id', '$key', '$achieved', datetime('now'));" 2>/dev/null \
    || config_fatal "config_ratchet_update: UPSERT NIE powiódł się dla '$service_id/$key'"
  printf '%s\n' "$achieved"
}

# ── config_kill_switch_check: sprawdza aktywne kill-switches (L7) ──────────
# Przed zastosowaniem wartości sprawdza, czy klucz nie jest wyłączony.
# Użycie: config_kill_switch_check <key> [value]
# Zwraca 0 = brak aktywnego kill-switcha (wartość można zastosować),
#         1 = aktywny kill-switch (wartość zablokowana).
config_kill_switch_check() {
  local key="$1" value="${2:-}"
  local db
  db="$(config_state_db)"
  local now
  now="$(date +%Y-%m-%d)"

  # Kill-switches z registry.yaml (sekcja kill_switches:).
  if [ -f "$CONFIG_REGISTRY" ]; then
    local in_k=0 cur_key="" cur_exp=""
    local line
    while IFS= read -r line; do
      if [[ "$line" =~ ^kill_switches:[[:space:]]*$ ]]; then in_k=1; continue; fi
      [ "$in_k" -eq 1 ] || continue
      if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*$ ]] && ! [[ "$line" =~ ^[[:space:]] ]]; then in_k=0; continue; fi
      if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]*key:[[:space:]]*\"?([^\"[:space:]]*)\"?[[:space:]]*$ ]]; then
        cur_key="${BASH_REMATCH[1]}"; cur_exp=""; continue
      fi
      if [[ "$line" =~ ^[[:space:]]{4}expires_at:[[:space:]]*\"?([^\"[:space:]]*)\"?[[:space:]]*$ ]]; then
        cur_exp="${BASH_REMATCH[1]}"
        if [ "$cur_key" = "$key" ] && [ -n "$cur_exp" ] && [ "$cur_exp" \> "$now" ]; then
          printf 'KILL-SWITCH: klucz %s jest wyłączony (L7, wygasa %s)\n' "$key" "$cur_exp" >&2
          return 1
        fi
      fi
    done < "$CONFIG_REGISTRY"
  fi

  # Kill-switches z StateStore (tabela config_kill_switches, jeśli istnieje).
  if [ -f "$db" ]; then
    local has_tbl
    has_tbl=$(sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table' AND name='config_kill_switches';" 2>/dev/null)
    if [ -n "$has_tbl" ]; then
      local cnt
      cnt=$(sqlite3 "$db" "SELECT COUNT(*) FROM config_kill_switches WHERE key='$key' AND expires_at > '$now';" 2>/dev/null)
      if [ "$cnt" -gt 0 ] 2>/dev/null; then
        printf 'KILL-SWITCH: klucz %s jest wyłączony (L7, aktywny kill-switch w StateStore)\n' "$key" >&2
        return 1
      fi
    fi
  fi

  return 0
}

# ── config_exemption_check: konstytucja niekonfigurowalnych ────────────────
# Klucz z listy niekonfigurowalnych NIE może być zmieniony przez config
# (tylko kod + ADR). Root bootstrap (ścieżka DB, ścieżka registry) to jedyne
# stałe wpisy — bez daty wygaśnięcia, explicite.
# Użycie: config_exemption_check <key>
# Zwraca 0 = klucz NIE jest niekonfigurowalny (można konfigurować),
#         1 = klucz jest niekonfigurowalny (zablokowany).
config_exemption_check() {
  local key="$1"

  # config_exemptions.yaml — lista niekonfigurowalnych kluczy.
  if [ ! -f "$CONFIG_EXEMPTIONS" ]; then
    # Brak pliku exemptions = brak niekonfigurowalnych (fail-open dla tej listy,
    # ale to NIE jest cichy default configu — to brak konstytucji).
    # Fail-closed: bez konstytucji nie wiemy, czego nie wolno konfigurować.
    # Zgodnie z design doc konstytucja jest fundamentem — jej brak = błąd.
    config_fatal "Brak config_exemptions.yaml: $CONFIG_EXEMPTIONS — konstytucja niekonfigurowalnych nie istnieje"
  fi

  # Sekcja non_configurable: — lista kluczy.
  local in_nc=0
  local line
  while IFS= read -r line; do
    if [[ "$line" =~ ^non_configurable:[[:space:]]*$ ]]; then in_nc=1; continue; fi
    [ "$in_nc" -eq 1 ] || continue
    if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*$ ]] && ! [[ "$line" =~ ^[[:space:]] ]]; then in_nc=0; continue; fi
    # Wpis: "  - key: gates.self-001.enabled" lub "  - gates.self-001.enabled"
    if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]*(key:[[:space:]]*)?\"?([a-zA-Z0-9_.-]+)\"?[[:space:]]*$ ]]; then
      local nc_key="${BASH_REMATCH[2]}"
      if [ "$nc_key" = "$key" ]; then
        printf 'EXEMPTION: klucz %s jest niekonfigurowalny (konstytucja) — zmiana tylko przez kod + ADR\n' "$key" >&2
        return 1
      fi
    fi
  done < "$CONFIG_EXEMPTIONS"

  return 0
}

# ── config_simulate: CFG-SIM — symulacja dry-run ───────────────────────────
# Dla każdego aktywnego serwisu × kontekstu: resolve(stary) vs resolve(nowy),
# diff. Wykrywa GATE_LOST i THRESHOLD_LOOSENED.
# Niepusty wynik = PR wymaga explicite aprobaty platformy albo waivera.
# Użycie: config_simulate <context_json> [service_id]
# Zwraca 0 = brak GATE_LOST/THRESHOLD_LOOSENED (bezpieczna zmiana),
#         1 = wykryto GATE_LOST lub THRESHOLD_LOOSENED (wymaga aprobaty).
config_simulate() {
  local context_json="${1:--}"
  local service_id="${2:-}"

  # Stary config = bieżący snapshot (ostatni w config_snapshots).
  # Nowy config = resolve z bieżącego registry.
  local db
  db="$(config_state_db)"
  config_require_sqlite

  [ -f "$db" ] || config_fatal "Brak bazy StateStore: $db — config_simulate wymaga bazy"
  local has_tbl
  has_tbl=$(sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table' AND name='config_snapshots';" 2>/dev/null)
  [ -n "$has_tbl" ] || config_fatal "Brak tabeli config_snapshots w StateStore — migracja 0006 nie została zastosowana"

  # Stary snapshot (ostatni wg id).
  local old_eff
  old_eff=$(sqlite3 "$db" "SELECT effective_json FROM config_snapshots ORDER BY id DESC LIMIT 1;" 2>/dev/null)

  # Nowy resolve — wywołany w bieżącym procesie (NIE w subshell), aby
  # CFG_EFFECTIVE pozostało dostępne do porównania. config_resolve zapisuje
  # snapshot_id do CFG_LAST_SNAPSHOT_ID; stdout (snapshot_id) jest zbędny.
  config_resolve "$context_json" "$service_id" >/dev/null || config_fatal "config_simulate: resolve(nowy) NIE powiódł się"
  local new_sid="$CFG_LAST_SNAPSHOT_ID"
  local new_eff
  new_eff=$(sqlite3 "$db" "SELECT effective_json FROM config_snapshots WHERE id='$new_sid';" 2>/dev/null)

  local issues=0
  local key old_val new_val
  # Porównaj wszystkie klucze z nowego configu.
  for key in "${!CFG_EFFECTIVE[@]}"; do
    new_val="${CFG_EFFECTIVE[$key]}"
    old_val=$(printf '%s' "$old_eff" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p")

    if [ -z "$old_val" ]; then
      # Klucz nie istniał w starym configu — nowy gate dodany (GATE_LOST nie dotyczy).
      continue
    fi

    if [ -z "$new_val" ]; then
      # Klucz zniknął z nowego configu → GATE_LOST.
      printf 'GATE_LOST: %s (stary=%s, nowy=brak)\n' "$key" "$old_val"
      issues=$((issues+1))
      continue
    fi

    # THRESHOLD_LOOSENED: nowa wartość jest luźniejsza niż stara.
    #   min_*: luźniejsza = niższa (new < old).
    #   max_*: luźniejsza = wyższa (new > old).
    if config_is_numeric "$old_val" && config_is_numeric "$new_val"; then
      local floor_dir
      floor_dir="$(config_floor_direction "$key")"
      local loosened=false
      if { [ "$floor_dir" = "max" ] && config_num_gt "$new_val" "$old_val"; } || \
         { [ "$floor_dir" = "min" ] && config_num_lt "$new_val" "$old_val"; }; then
        loosened=true
      fi
      if [ "$loosened" = "true" ]; then
        printf 'THRESHOLD_LOOSENED: %s (stary=%s, nowy=%s)\n' "$key" "$old_val" "$new_val"
        issues=$((issues+1))
      fi
    fi
  done

  if [ "$issues" -gt 0 ]; then
    printf 'CFG-SIM: wykryto %s problemów — PR wymaga explicite aprobaty platformy albo waivera\n' "$issues" >&2
    return 1
  fi
  printf 'CFG-SIM: brak GATE_LOST/THRESHOLD_LOOSENED — zmiana bezpieczna\n'
  return 0
}

