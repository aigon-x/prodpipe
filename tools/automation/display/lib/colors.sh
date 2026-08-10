#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# colors.sh — Visual Pipeline Display — paleta kolorów (ANSI dark)
# ─────────────────────────────────────────────────────────────
# Definiuje paletę ANSI dla terminala (dark theme) oraz mapowanie
# semantyczne: rodzina pipeline'a → kolor, klasa → kolor, status → kolor.
#
# Zasady:
#   * Kolory są aktywne TYLKO gdy stdout jest TTY (jak lib.sh).
#   * Identyfikatory po angielsku, komentarze po polsku.
#   * Każdy kolor ma wariant "dim" (przygaszony) dla tła/ramek.
# ─────────────────────────────────────────────────────────────
set -u

# ── Bazowe kolory ANSI (dark theme) ─────────────────────────
if [ -t 1 ]; then
  D_C_RESET=$'\033[0m'
  D_C_BOLD=$'\033[1m'
  D_C_DIM=$'\033[2m'
  D_C_RED=$'\033[31m'
  D_C_GREEN=$'\033[32m'
  D_C_YELLOW=$'\033[33m'
  D_C_BLUE=$'\033[34m'
  D_C_MAGENTA=$'\033[35m'
  D_C_CYAN=$'\033[36m'
  D_C_WHITE=$'\033[37m'
  D_C_BRIGHT_RED=$'\033[91m'
  D_C_BRIGHT_GREEN=$'\033[92m'
  D_C_BRIGHT_YELLOW=$'\033[93m'
  D_C_BRIGHT_BLUE=$'\033[94m'
  D_C_BRIGHT_MAGENTA=$'\033[95m'
  D_C_BRIGHT_CYAN=$'\033[96m'
  D_C_BRIGHT_WHITE=$'\033[97m'
  # Tła (dark theme — przygaszone).
  D_C_BG_RED=$'\033[41m'
  D_C_BG_GREEN=$'\033[42m'
  D_C_BG_YELLOW=$'\033[43m'
  D_C_BG_BLUE=$'\033[44m'
  D_C_BG_MAGENTA=$'\033[45m'
  D_C_BG_CYAN=$'\033[46m'
else
  D_C_RESET=""; D_C_BOLD=""; D_C_DIM=""
  D_C_RED=""; D_C_GREEN=""; D_C_YELLOW=""; D_C_BLUE=""
  D_C_MAGENTA=""; D_C_CYAN=""; D_C_WHITE=""
  D_C_BRIGHT_RED=""; D_C_BRIGHT_GREEN=""; D_C_BRIGHT_YELLOW=""
  D_C_BRIGHT_BLUE=""; D_C_BRIGHT_MAGENTA=""; D_C_BRIGHT_CYAN=""
  D_C_BRIGHT_WHITE=""
  D_C_BG_RED=""; D_C_BG_GREEN=""; D_C_BG_YELLOW=""; D_C_BG_BLUE=""
  D_C_BG_MAGENTA=""; D_C_BG_CYAN=""
fi

# ── Mapowanie rodzina → kolor ───────────────────────────────
# 13 rodzin pipeline'ów. Każda ma przypisany kolor ANSI.
# Użycie: d_family_color <FAMILY> → wypisuje kod ANSI.
d_family_color() {
  local family="$1"
  case "$family" in
    PRODUCT)            echo "$D_C_BRIGHT_CYAN" ;;
    DESIGN)             echo "$D_C_BRIGHT_BLUE" ;;
    SECURITY)           echo "$D_C_BRIGHT_RED" ;;
    CODE)               echo "$D_C_BRIGHT_GREEN" ;;
    BUILD)              echo "$D_C_BRIGHT_YELLOW" ;;
    DEPLOYMENT)         echo "$D_C_BRIGHT_MAGENTA" ;;
    RUNTIME)            echo "$D_C_CYAN" ;;
    RECOVERY)           echo "$D_C_BRIGHT_WHITE" ;;
    GTM)                echo "$D_C_YELLOW" ;;
    AI)                 echo "$D_C_MAGENTA" ;;
    OFFENSIVE-SECURITY) echo "$D_C_RED" ;;
    HUMAN-SIMULATION)   echo "$D_C_BLUE" ;;
    SIMULATION)         echo "$D_C_GREEN" ;;
    *)                  echo "$D_C_WHITE" ;;
  esac
}

# ── Mapowanie klasa → kolor ─────────────────────────────────
# 5 klas wykonania (L0-L4).
d_class_color() {
  local class="$1"
  case "$class" in
    FAST)       echo "$D_C_BRIGHT_GREEN" ;;
    STANDARD)   echo "$D_C_BRIGHT_CYAN" ;;
    DEEP)       echo "$D_C_BRIGHT_YELLOW" ;;
    RELEASE)    echo "$D_C_BRIGHT_MAGENTA" ;;
    CONTINUOUS) echo "$D_C_BRIGHT_BLUE" ;;
    *)          echo "$D_C_WHITE" ;;
  esac
}

# ── Mapowanie status → kolor ────────────────────────────────
d_status_color() {
  local status="$1"
  case "$status" in
    IMPLEMENTED) echo "$D_C_BRIGHT_GREEN" ;;
    PROPOSED)    echo "$D_C_BRIGHT_YELLOW" ;;
    *)           echo "$D_C_WHITE" ;;
  esac
}

# ── Mapowanie werdykt/status evidence → kolor ───────────────
d_verdict_color() {
  local verdict="$1"
  case "$verdict" in
    PASS)            echo "$D_C_BRIGHT_GREEN" ;;
    FAIL)            echo "$D_C_BRIGHT_RED" ;;
    NOT_APPLICABLE)  echo "$D_C_BRIGHT_YELLOW" ;;
    *)               echo "$D_C_WHITE" ;;
  esac
}

# ── Pomocniczy: kolorowany tekst ────────────────────────────
# Użycie: d_paint <kod_ansi> <tekst>
d_paint() {
  local color="$1"; shift
  printf '%s%s%s' "$color" "$*" "$D_C_RESET"
}
