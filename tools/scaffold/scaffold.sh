#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# scaffold.sh — AIGON Production Platform — Scaffold
# Minimalny, deterministyczny scaffold: template + project manifest
# → nowy, izolowany projekt.
#
# Kontrakt: contracts/scaffold/contract.md (STATUS: DRAFT, zatwierdzony).
#
# 7 kroków:
#   1. LOAD          — wczytaj project manifest (YAML).
#   2. VALIDATE      — waliduj manifest fail-closed (8 pól, zamknięta lista typów).
#   3. RESOLVE       — rozwiąż template (ścieżka, wersja z VERSION).
#   4. COPY          — skopiuj strukturę template'a do project root (bez sekretów/artefaktów).
#   5. SUBSTITUTE    — podstaw jawnie oznaczone tokeny ({{project.*}}, {{template.version}}).
#   6. WRITE-MANIFEST— zapisz manifest w nowym projekcie (traceability).
#   7. SELF-CHECK    — zweryfikuj kompletność i izolację nowego projektu.
#
# Twardy Template Drift Guard (P0 gate): TEMPLATE BEFORE == TEMPLATE AFTER.
# Scaffold NIE jest meta-systemem, NIE jest Runtime'em, NIE deployuje.
#
# Użycie: ./scaffold.sh <manifest.yaml>
# ─────────────────────────────────────────────────────────────
set -u

# ── Lokalizacje ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_ROOT="$REPO_ROOT"
VERSION_FILE="$REPO_ROOT/VERSION"
REGISTRY="$REPO_ROOT/config/canonical/registry.yaml"

# ── Zamknięta lista typów projektów (z kontraktu) ────────────
# NIE rozszerzaj — kontrakt definiuje dokładnie te 10 typów.
PROJECT_TYPES="minimal cli rust-backend python-service web ai distributed data multi-service filesystem"

# ── Tokeny substytucji (jawnie oznaczone) ────────────────────
# Scaffold podstawia TYLKO te tokeny. Nigdy regex na całym pliku.
SUBSTITUTION_TOKENS=(
  "{{project.identity}}"
  "{{project.type}}"
  "{{project.profile}}"
  "{{project.name}}"
  "{{project.root}}"
  "{{template.version}}"
)

# ── Katalogi/pliki wykluczone z kopiowania ───────────────────
# Scaffold kopiuje strukturę template'a BEZ sekretów, artefaktów,
# runtime state, cache i meta-systemów. To jest deterministyczna
# lista — nie zależy od .gitignore (który może się zmieniać).
COPY_EXCLUDE=(
  ".git"
  ".qwen"
  ".tools"
  "secrets"
  "artifacts"
  "out"
  "target"
  "build"
  "dist"
  "node_modules"
  "__pycache__"
  ".venv"
  "venv"
  ".pytest_cache"
  ".mypy_cache"
  ".ruff_cache"
  "data"
  "logs"
  "coverage"
)

# ── Kolory (jeśli TTY) ───────────────────────────────────────
if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_CYAN=$'\033[36m'; C_BOLD=$'\033[1m'; C_RESET=$'\033[0m'
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_BOLD=""; C_RESET=""
fi

say()  { printf '%s\n' "$*"; }
sayc() { printf '%s%s%s\n' "$2" "$1" "$C_RESET"; }

# ── Globalny stan ────────────────────────────────────────────
SCAFFOLD_FAIL=0
scaffold_fail() { SCAFFOLD_FAIL=$((SCAFFOLD_FAIL+1)); sayc "[FAIL] $*" "$C_RED"; }
scaffold_pass() { sayc "[PASS] $*" "$C_GREEN"; }

# ── Pomoc ────────────────────────────────────────────────────
usage() {
  cat <<'EOF'
Użycie: ./scaffold.sh <manifest.yaml>

Tworzy nowy, izolowany projekt z template'a (Prod-ready) na podstawie
project manifest (YAML, 8 pól). Deterministyczny, fail-closed.

Manifest (wszystkie pola wymagane):
  schema_version: 1
  project:
    identity: t01-minimal        # slug, [a-z0-9-]
    type: minimal                # z zamkniętej listy 10 typów
    profile: fast                # z registry.yaml
    name: "T01 Minimal"          # display name
    config: {}                   # override (opcjonalnie)
    root: ./out/t01              # ścieżka docelowa
  template:
    version: 0.1.0               # musi zgadzać się z VERSION

Typy projektów: minimal cli rust-backend python-service web ai
                distributed data multi-service filesystem
EOF
  exit 2
}

# ── Krok 1: LOAD ─────────────────────────────────────────────
# Wczytuje manifest YAML i wypisuje go jako "key=value" (płaska mapa).
# Fail-closed: nieznane pole = błąd (scaffold nie rozszerza kontraktu).
load_manifest() {
  local manifest="$1"
  if [ ! -f "$manifest" ]; then
    scaffold_fail "LOAD: brak pliku manifestu: $manifest"
    return 1
  fi
  # Walidacja YAML + ekstrakcja pól. Nieznane pole → błąd.
  python3 - "$manifest" <<'PYEOF' || { scaffold_fail "LOAD: manifest nie jest poprawnym YAML lub zawiera nieznane pole"; return 1; }
import sys, yaml
with open(sys.argv[1]) as f:
    d = yaml.safe_load(f) or {}
assert isinstance(d, dict), "manifest nie jest mapą"
# Dozwolone pola (zamknięty zbiór — nie rozszerzaj kontraktu).
allowed = {"schema_version", "project", "template"}
unknown = set(d.keys()) - allowed
if unknown:
    raise SystemExit(f"nieznane pole: {sorted(unknown)}")
proj = d.get("project") or {}
assert isinstance(proj, dict), "project musi być mapą"
allowed_proj = {"identity", "type", "profile", "name", "config", "root"}
unknown_proj = set(proj.keys()) - allowed_proj
if unknown_proj:
    raise SystemExit(f"nieznane pole project: {sorted(unknown_proj)}")
tpl = d.get("template") or {}
assert isinstance(tpl, dict), "template musi być mapą"
allowed_tpl = {"version"}
unknown_tpl = set(tpl.keys()) - allowed_tpl
if unknown_tpl:
    raise SystemExit(f"nieznane pole template: {sorted(unknown_tpl)}")
# Wypisz płaską mapę key=value (config jako JSON).
print(f"schema_version={d.get('schema_version')}")
print(f"project.identity={proj.get('identity')}")
print(f"project.type={proj.get('type')}")
print(f"project.profile={proj.get('profile')}")
print(f"project.name={proj.get('name')}")
print(f"project.config={yaml.safe_dump(proj.get('config') or {}, default_flow_style=True).strip()}")
print(f"project.root={proj.get('root')}")
print(f"template.version={tpl.get('version')}")
PYEOF
}

# ── Krok 2: VALIDATE ─────────────────────────────────────────
# Waliduje manifest fail-closed. Zwraca 0 jeśli poprawny, 1 w przeciwnym razie.
validate_manifest() {
  local schema_version="$1" identity="$2" type="$3" profile="$4" name="$5" root="$6" tpl_version="$7"
  local ok=0

  # schema_version musi być 1 (wersja kontraktu manifestu).
  if [ "$schema_version" != "1" ]; then
    scaffold_fail "VALIDATE: schema_version=$schema_version (oczekiwano 1)"
    ok=1
  fi

  # project.identity — slug, lowercase, [a-z0-9-].
  if ! printf '%s' "$identity" | grep -qE '^[a-z0-9-]+$'; then
    scaffold_fail "VALIDATE: project.identity='$identity' nie jest slugiem ([a-z0-9-])"
    ok=1
  fi

  # project.type — zamknięta lista typów.
  if ! printf '%s\n' $PROJECT_TYPES | grep -qx "$type"; then
    scaffold_fail "VALIDATE: project.type='$type' nie jest na zamkniętej liście typów"
    ok=1
  fi

  # project.profile — musi istnieć w registry.yaml.
  if ! python3 - "$REGISTRY" "$profile" <<'PYEOF' >/dev/null 2>&1
import sys, yaml
with open(sys.argv[1]) as f:
    d = yaml.safe_load(f) or {}
profiles = d.get("profiles") or {}
assert sys.argv[2] in profiles, f"profil '{sys.argv[2]}' nie istnieje w registry.yaml"
PYEOF
  then
    scaffold_fail "VALIDATE: project.profile='$profile' nie istnieje w registry.yaml"
    ok=1
  fi

  # project.name — niepusty.
  if [ -z "$name" ]; then
    scaffold_fail "VALIDATE: project.name jest puste"
    ok=1
  fi

  # project.root — niepusty, nie wskazuje na template root.
  if [ -z "$root" ]; then
    scaffold_fail "VALIDATE: project.root jest puste"
    ok=1
  fi
  # Rozwiąż ścieżkę względną do absolutnej.
  local abs_root
  abs_root="$(cd "$REPO_ROOT" && realpath -m "$root" 2>/dev/null || echo "$REPO_ROOT/$root")"
  if [ "$abs_root" = "$TEMPLATE_ROOT" ]; then
    scaffold_fail "VALIDATE: project.root='$root' wskazuje na template root (kolizja)"
    ok=1
  fi

  # template.version — musi zgadzać się z VERSION.
  local actual_version
  actual_version="$(cat "$VERSION_FILE" 2>/dev/null || echo "")"
  if [ "$tpl_version" != "$actual_version" ]; then
    scaffold_fail "VALIDATE: template.version='$tpl_version' nie zgadza się z VERSION='$actual_version'"
    ok=1
  fi

  [ "$ok" -eq 0 ]
}

# ── Krok 3: RESOLVE ──────────────────────────────────────────
# Rozwiązuje template: potwierdza że template root istnieje i wersja się zgadza.
resolve_template() {
  if [ ! -d "$TEMPLATE_ROOT" ]; then
    scaffold_fail "RESOLVE: template root nie istnieje: $TEMPLATE_ROOT"
    return 1
  fi
  if [ ! -f "$VERSION_FILE" ]; then
    scaffold_fail "RESOLVE: brak pliku VERSION w template: $VERSION_FILE"
    return 1
  fi
  scaffold_pass "RESOLVE: template=$TEMPLATE_ROOT version=$(cat "$VERSION_FILE")"
}

# ── Fingerprint template'a (Template Drift Guard) ───────────
# Hash wszystkich plików template'a (git-tracked + nieignorowane).
# Używamy git ls-files (jak repo_files w lib.sh) — deterministyczne,
# nie skanuje nieśledzonych artefaktów roboczych.
template_fingerprint() {
  ( cd "$TEMPLATE_ROOT" && git ls-files 2>/dev/null | sort | xargs -r sha256sum 2>/dev/null | sha256sum | awk '{print $1}' )
}

# ── Krok 4: COPY ─────────────────────────────────────────────
# Kopiuje strukturę template'a do project root, pomijając wykluczone
# katalogi/pliki. Używa git ls-files (deterministyczne, tylko śledzone).
# Uwaga: pętla działa w GŁÓWNYM procesie (process substitution, nie pipe),
# więc scaffold_fail/scaffold_pass i liczniki propagują się poprawnie.
copy_template() {
  local dest="$1"
  local copied=0
  # Utwórz dest.
  mkdir -p "$dest" || { scaffold_fail "COPY: nie można utworzyć $dest"; return 1; }
  # Kopiuj każdy git-tracked plik, pomijając wykluczone.
  local f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    # Pomiń pliki w wykluczonych katalogach.
    local skip=0 ex
    for ex in "${COPY_EXCLUDE[@]}"; do
      case "$f" in
        "$ex"/*|"$ex") skip=1; break ;;
      esac
    done
    [ "$skip" -eq 1 ] && continue
    # Pomiń pliki sekretów / artefaktów / runtime state.
    case "$f" in
      *.env|*.pem|*.key|*.crt|*.p12|*.pfx|*.jks|*.db|*.sqlite|*.sqlite3|*.log) continue ;;
    esac
    local src="$TEMPLATE_ROOT/$f"
    local dst="$dest/$f"
    mkdir -p "$(dirname "$dst")" || continue
    cp "$src" "$dst" 2>/dev/null || continue
    copied=$((copied+1))
  done < <(cd "$TEMPLATE_ROOT" && git ls-files 2>/dev/null)
  if [ "$copied" -eq 0 ]; then
    scaffold_fail "COPY: nie skopiowano żadnych plików (pusty template?)"
    return 1
  fi
  scaffold_pass "COPY: skopiowano $copied plików do $dest"
}

# ── Krok 5: SUBSTITUTE ───────────────────────────────────────
# Podstawia jawnie oznaczone tokeny w plikach nowego projektu.
# Tylko tokeny z SUBSTITUTION_TOKENS. Nigdy regex na całym pliku.
substitute() {
  local dest="$1"
  local identity="$2" type="$3" profile="$4" name="$5" root="$6" tpl_version="$7"
  local substituted=0
  # Mapowanie token → wartość.
  local -A vals
  vals["{{project.identity}}"]="$identity"
  vals["{{project.type}}"]="$type"
  vals["{{project.profile}}"]="$profile"
  vals["{{project.name}}"]="$name"
  vals["{{project.root}}"]="$root"
  vals["{{template.version}}"]="$tpl_version"
  # Przetwarzaj pliki tekstowe (pomijaj binaria). Główny proces (process substitution).
  # Nowy projekt NIE ma .git (izolacja) — używamy find, pomijając .scaffold/.
  local f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$f" ] || continue
    # Pomiń binaria (sprawdź przez file).
    if file "$f" 2>/dev/null | grep -qE 'binary|executable'; then
      continue
    fi
    local changed=0 tok
    for tok in "${SUBSTITUTION_TOKENS[@]}"; do
      if grep -qF "$tok" "$f" 2>/dev/null; then
        # Podstaw token na wartość (literalnie, nie regex).
        sed -i "s|${tok}|${vals[$tok]}|g" "$f" 2>/dev/null
        changed=1
      fi
    done
    [ "$changed" -eq 1 ] && substituted=$((substituted+1))
  done < <(find "$dest" -type f -not -path "$dest/.scaffold/*" 2>/dev/null)
  scaffold_pass "SUBSTITUTE: podstawiono tokeny w $substituted plikach"
}

# ── Krok 6: WRITE-MANIFEST ───────────────────────────────────
# Zapisuje manifest w nowym projekcie (traceability).
write_manifest() {
  local dest="$1" manifest="$2"
  mkdir -p "$dest/.scaffold"
  cp "$manifest" "$dest/.scaffold/project-manifest.yaml" 2>/dev/null || {
    scaffold_fail "WRITE-MANIFEST: nie można zapisać manifestu w $dest/.scaffold/"
    return 1
  }
  scaffold_pass "WRITE-MANIFEST: zapisano manifest w $dest/.scaffold/project-manifest.yaml"
}

# ── Krok 7: SELF-CHECK ───────────────────────────────────────
# Weryfikuje kompletność i izolację nowego projektu.
self_check() {
  local dest="$1"
  local ok=0
  # Kompletność: dest istnieje i nie jest pusty.
  if [ ! -d "$dest" ]; then
    scaffold_fail "SELF-CHECK: project root nie istnieje: $dest"
    ok=1
  fi
  # Izolacja: dest NIE zawiera .git (nie jest klonem template'a).
  if [ -d "$dest/.git" ]; then
    scaffold_fail "SELF-CHECK: project root zawiera .git (nie jest izolowany)"
    ok=1
  fi
  # Izolacja: dest NIE zawiera sekretów.
  if [ -d "$dest/secrets" ]; then
    scaffold_fail "SELF-CHECK: project root zawiera secrets/ (nie jest izolowany)"
    ok=1
  fi
  # Kompletność: manifest został zapisany.
  if [ ! -f "$dest/.scaffold/project-manifest.yaml" ]; then
    scaffold_fail "SELF-CHECK: brak zapisanego manifestu w $dest/.scaffold/"
    ok=1
  fi
  [ "$ok" -eq 0 ] && scaffold_pass "SELF-CHECK: nowy projekt kompletny i izolowany"
  [ "$ok" -eq 0 ]
}

# ── Główny przepływ ──────────────────────────────────────────
main() {
  [ $# -ge 1 ] || usage
  local manifest="$1"

  say "=== SCAFFOLD ==="
  say "Template: $TEMPLATE_ROOT"
  say "Manifest: $manifest"
  say ""

  # ── Template Drift Guard: fingerprint PRZED ────────────────
  local fp_before
  fp_before="$(template_fingerprint)"
  say "Template fingerprint (before): $fp_before"
  say ""

  # ── Krok 1: LOAD ───────────────────────────────────────────
  local loaded
  loaded="$(load_manifest "$manifest")" || return 1
  # Parsuj key=value.
  local schema_version identity type profile name root tpl_version
  schema_version="$(printf '%s\n' "$loaded" | sed -n 's/^schema_version=//p')"
  identity="$(printf '%s\n' "$loaded" | sed -n 's/^project.identity=//p')"
  type="$(printf '%s\n' "$loaded" | sed -n 's/^project.type=//p')"
  profile="$(printf '%s\n' "$loaded" | sed -n 's/^project.profile=//p')"
  name="$(printf '%s\n' "$loaded" | sed -n 's/^project.name=//p')"
  root="$(printf '%s\n' "$loaded" | sed -n 's/^project.root=//p')"
  tpl_version="$(printf '%s\n' "$loaded" | sed -n 's/^template.version=//p')"
  scaffold_pass "LOAD: manifest wczytany (identity=$identity, type=$type)"

  # ── Krok 2: VALIDATE ───────────────────────────────────────
  if ! validate_manifest "$schema_version" "$identity" "$type" "$profile" "$name" "$root" "$tpl_version"; then
    say ""
    sayc "=== SCAFFOLD: FAIL (walidacja manifestu) ===" "$C_RED"
    return 1
  fi
  scaffold_pass "VALIDATE: manifest poprawny (fail-closed)"

  # ── Krok 3: RESOLVE ────────────────────────────────────────
  resolve_template || return 1

  # ── Rozwiąż project.root do absolutnej ścieżki ─────────────
  local abs_root
  abs_root="$(cd "$REPO_ROOT" && realpath -m "$root" 2>/dev/null || echo "$REPO_ROOT/$root")"

  # ── Kolizja destination: nie nadpisuj istniejącego projektu ─
  if [ -e "$abs_root" ]; then
    scaffold_fail "RESOLVE: destination już istnieje: $abs_root (kolizja)"
    say ""
    sayc "=== SCAFFOLD: FAIL (kolizja destination) ===" "$C_RED"
    return 1
  fi

  # ── Krok 4: COPY ───────────────────────────────────────────
  copy_template "$abs_root" || return 1

  # ── Krok 5: SUBSTITUTE ─────────────────────────────────────
  substitute "$abs_root" "$identity" "$type" "$profile" "$name" "$root" "$tpl_version"

  # ── Krok 6: WRITE-MANIFEST ────────────────────────────────
  write_manifest "$abs_root" "$manifest" || return 1

  # ── Krok 7: SELF-CHECK ─────────────────────────────────────
  self_check "$abs_root" || return 1

  # ── Template Drift Guard: fingerprint PO ───────────────────
  local fp_after
  fp_after="$(template_fingerprint)"
  say ""
  say "Template fingerprint (after):  $fp_after"
  if [ "$fp_before" = "$fp_after" ]; then
    scaffold_pass "TEMPLATE DRIFT = 0 (fingerprint identyczny przed/po)"
  else
    scaffold_fail "TEMPLATE DRIFT != 0 (P0 gate) — template został zmodyfikowany"
    say ""
    sayc "=== SCAFFOLD: FAIL (TEMPLATE DRIFT) ===" "$C_RED"
    return 1
  fi

  # ── Podsumowanie ───────────────────────────────────────────
  say ""
  say "=== SCAFFOLD — WYNIK ==="
  if [ "$SCAFFOLD_FAIL" -eq 0 ]; then
    sayc "SCAFFOLD: PASS" "$C_GREEN"
    say "Nowy projekt: $abs_root"
    return 0
  else
    sayc "SCAFFOLD: FAIL ($SCAFFOLD_FAIL błędów)" "$C_RED"
    return 1
  fi
}

main "$@"
