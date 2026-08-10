#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# lib/security.sh — SECRET REDACTION
# Nigdy nie zapisuj realnych sekretów do wygenerowanego wyjścia.
# Redaguje wzorce sekretów (klucze, tokeny, hasła) w danych
# przed zapisem do modelu / raportów.
# ─────────────────────────────────────────────────────────────
set -u

# ── Wzorce sekretów (regex) ─────────────────────────────────
# Każdy wzorzec jest redagowany do "[REDACTED]".
SECRET_PATTERNS=(
  'sk-[A-Za-z0-9]{16,}'
  'AKIA[0-9A-Z]{16}'
  'ghp_[A-Za-z0-9]{20,}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'AIza[0-9A-Za-z_-]{20,}'
  'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
)

# ── Redaguj sekrety w tekście ───────────────────────────────
# Użycie: redact <tekst>
# Zwraca zredagowany tekst na stdout.
redact() {
  local text="$1"
  local pat
  for pat in "${SECRET_PATTERNS[@]}"; do
    text="$(printf '%s' "$text" | sed -E "s/$pat/[REDACTED]/g")"
  done
  printf '%s' "$text"
}

# ── Czy tekst zawiera sekret? ───────────────────────────────
# Użycie: has_secret <tekst>
# Zwraca 0 jeśli znaleziono sekret, 1 w przeciwnym razie.
has_secret() {
  local text="$1"
  local pat
  for pat in "${SECRET_PATTERNS[@]}"; do
    if printf '%s' "$text" | grep -qE -- "$pat"; then
      return 0
    fi
  done
  return 1
}

# ── Redaguj plik (in-place) ─────────────────────────────────
# Użycie: redact_file <ścieżka>
redact_file() {
  local f="$1"
  [ -f "$f" ] || return 0
  local tmp
  tmp="$(mktemp)"
  redact "$(cat "$f")" > "$tmp"
  mv "$tmp" "$f"
}
