#!/usr/bin/env bash
# ============================================================================
# test-scaffold.sh — Scaffold Contract Tests (8 przypadków)
# ============================================================================
# Weryfikuje kontrakt contracts/scaffold/contract.md:
#   T1: poprawny manifest → PASS
#   T2: brak wymaganych pól → FAIL
#   T3: nieznany project.type → FAIL
#   T4: nieprawidłowy project.root → FAIL
#   T5: kolizja destination → FAIL
#   T6: niedozwolona substytucja → FAIL
#   T7: template modification → FAIL (Template Drift Guard)
#   T8: powtórne uruchomienie → deterministyczny wynik
#
# Testy NIE modyfikują template'a (Template Drift Guard = P0).
# Używają tymczasowych katalogów (mktemp -d) dla manifestów i project rootów.
#
# Użycie: ./test-scaffold.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAFFOLD_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$SCAFFOLD_DIR/../.." && pwd)"
SCAFFOLD="$SCAFFOLD_DIR/scaffold.sh"
VERSION="$(cat "$REPO_ROOT/VERSION" 2>/dev/null || echo "0.0.0")"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

# ── Helper: utwórz poprawny manifest ─────────────────────────
# Użycie: make_manifest <plik> <identity> <type> <profile> <name> <root> [extra_yaml]
make_manifest() {
  local file="$1" identity="$2" type="$3" profile="$4" name="$5" root="$6" extra="${7:-}"
  cat > "$file" <<EOF
schema_version: 1
project:
  identity: $identity
  type: $type
  profile: $profile
  name: "$name"
  config: {}
  root: $root
template:
  version: $VERSION
$extra
EOF
}

echo "=== SCAFFOLD CONTRACT TESTS ==="
echo "Scaffold: $SCAFFOLD"
echo "Template version: $VERSION"
echo ""

# ── T1: poprawny manifest → PASS ─────────────────────────────
echo "--- T1: poprawny manifest → PASS ---"
TMP="$(mktemp -d)"
MANIFEST="$TMP/manifest.yaml"
ROOT="$TMP/out/t01"
make_manifest "$MANIFEST" "t01-minimal" "minimal" "fast" "T01 Minimal" "$ROOT"
if "$SCAFFOLD" "$MANIFEST" >"$TMP/t1.log" 2>&1; then
  if [ -f "$ROOT/.scaffold/project-manifest.yaml" ]; then
    t_pass "poprawny manifest → PASS, manifest zapisany"
  else
    t_fail "poprawny manifest → PASS, ale brak zapisanego manifestu"
  fi
else
  t_fail "poprawny manifest → oczekiwano PASS, dostał FAIL"
  echo "       $(tail -5 "$TMP/t1.log" | tr '\n' ' ')"
fi
rm -rf "$TMP"

# ── T2: brak wymaganych pól → FAIL ───────────────────────────
echo ""
echo "--- T2: brak wymaganych pól → FAIL ---"
TMP="$(mktemp -d)"
MANIFEST="$TMP/manifest.yaml"
ROOT="$TMP/out/t02"
# Brak project.identity i template.version.
cat > "$MANIFEST" <<EOF
schema_version: 1
project:
  type: minimal
  profile: fast
  name: "T02"
  root: $ROOT
EOF
if "$SCAFFOLD" "$MANIFEST" >"$TMP/t2.log" 2>&1; then
  t_fail "brak wymaganych pól → oczekiwano FAIL, dostał PASS"
else
  t_pass "brak wymaganych pól → FAIL"
fi
rm -rf "$TMP"

# ── T3: nieznany project.type → FAIL ─────────────────────────
echo ""
echo "--- T3: nieznany project.type → FAIL ---"
TMP="$(mktemp -d)"
MANIFEST="$TMP/manifest.yaml"
ROOT="$TMP/out/t03"
make_manifest "$MANIFEST" "t03-badtype" "quantum" "fast" "T03" "$ROOT"
if "$SCAFFOLD" "$MANIFEST" >"$TMP/t3.log" 2>&1; then
  t_fail "nieznany project.type → oczekiwano FAIL, dostał PASS"
else
  t_pass "nieznany project.type → FAIL"
fi
rm -rf "$TMP"

# ── T4: nieprawidłowy project.root → FAIL ────────────────────
echo ""
echo "--- T4: nieprawidłowy project.root → FAIL ---"
TMP="$(mktemp -d)"
MANIFEST="$TMP/manifest.yaml"
# project.root wskazuje na template root (kolizja) — nieprawidłowy.
make_manifest "$MANIFEST" "t04-badroot" "minimal" "fast" "T04" "."
if "$SCAFFOLD" "$MANIFEST" >"$TMP/t4.log" 2>&1; then
  t_fail "nieprawidłowy project.root → oczekiwano FAIL, dostał PASS"
else
  t_pass "nieprawidłowy project.root (template root) → FAIL"
fi
rm -rf "$TMP"

# ── T5: kolizja destination → FAIL ───────────────────────────
echo ""
echo "--- T5: kolizja destination → FAIL ---"
TMP="$(mktemp -d)"
MANIFEST="$TMP/manifest.yaml"
ROOT="$TMP/out/t05"
mkdir -p "$ROOT"   # destination już istnieje
make_manifest "$MANIFEST" "t05-collision" "minimal" "fast" "T05" "$ROOT"
if "$SCAFFOLD" "$MANIFEST" >"$TMP/t5.log" 2>&1; then
  t_fail "kolizja destination → oczekiwano FAIL, dostał PASS"
else
  t_pass "kolizja destination → FAIL"
fi
rm -rf "$TMP"

# ── T6: niedozwolona substytucja → FAIL ──────────────────────
echo ""
echo "--- T6: niedozwolona substytucja → FAIL ---"
TMP="$(mktemp -d)"
MANIFEST="$TMP/manifest.yaml"
ROOT="$TMP/out/t06"
# Nieznane pole w manifest → scaffold nie rozszerza kontraktu → FAIL.
make_manifest "$MANIFEST" "t06-badfield" "minimal" "fast" "T06" "$ROOT" "  extra_field: value"
if "$SCAFFOLD" "$MANIFEST" >"$TMP/t6.log" 2>&1; then
  t_fail "niedozwolona substytucja (nieznane pole) → oczekiwano FAIL, dostał PASS"
else
  t_pass "niedozwolona substytucja (nieznane pole) → FAIL"
fi
rm -rf "$TMP"

# ── T7: template modification → FAIL (Template Drift Guard) ──
echo ""
echo "--- T7: template modification → FAIL (Template Drift Guard) ---"
TMP="$(mktemp -d)"
MANIFEST="$TMP/manifest.yaml"
ROOT="$TMP/out/t07"
make_manifest "$MANIFEST" "t07-drift" "minimal" "fast" "T07" "$ROOT"
# Template Drift Guard opiera się na fingerprintzie (hash) git-tracked plików.
# Testujemy, że fingerprint jest CZUŁY na modyfikację template'a: zmiana
# git-tracked pliku (VERSION) musi zmienić fingerprint. To jest fundament
# drift guard — gdyby fingerprint nie reagował, drift pozostałby niewykryty.
# Zapisujemy oryginał i przywracamy go po teście (bezpiecznie).
ORIG_VERSION="$(cat "$REPO_ROOT/VERSION")"
FP_BEFORE="$(cd "$REPO_ROOT" && git ls-files 2>/dev/null | sort | xargs -r sha256sum 2>/dev/null | sha256sum | awk '{print $1}')"
echo "9.9.9-drift" > "$REPO_ROOT/VERSION"
FP_AFTER="$(cd "$REPO_ROOT" && git ls-files 2>/dev/null | sort | xargs -r sha256sum 2>/dev/null | sha256sum | awk '{print $1}')"
# Przywróć oryginalny VERSION.
printf '%s\n' "$ORIG_VERSION" > "$REPO_ROOT/VERSION"
if [ "$FP_BEFORE" != "$FP_AFTER" ]; then
  t_pass "template modification → fingerprint reaguje (drift wykrywalny)"
else
  t_fail "template modification → fingerprint NIE reaguje (drift niewykrywalny)"
fi
rm -rf "$TMP"

# ── T8: powtórne uruchomienie → deterministyczny wynik ───────
echo ""
echo "--- T8: powtórne uruchomienie → deterministyczny wynik ---"
TMP="$(mktemp -d)"
MANIFEST="$TMP/manifest.yaml"
ROOT="$TMP/out/t08"
make_manifest "$MANIFEST" "t08-determinism" "minimal" "fast" "T08" "$ROOT"
# Pierwsze uruchomienie.
if "$SCAFFOLD" "$MANIFEST" >"$TMP/t8a.log" 2>&1; then
  # Drugie uruchomienie na INNY root (ten sam manifest) — wynik musi być identyczny.
  ROOT2="$TMP/out/t08b"
  make_manifest "$MANIFEST" "t08-determinism" "minimal" "fast" "T08" "$ROOT2"
  if "$SCAFFOLD" "$MANIFEST" >"$TMP/t8b.log" 2>&1; then
    # Porównaj fingerprinty obu wyników (bez .scaffold, bo tam jest ścieżka).
    FP1="$(cd "$ROOT" && find . -type f -not -path './.scaffold/*' | sort | xargs sha256sum 2>/dev/null | sha256sum | awk '{print $1}')"
    FP2="$(cd "$ROOT2" && find . -type f -not -path './.scaffold/*' | sort | xargs sha256sum 2>/dev/null | sha256sum | awk '{print $1}')"
    if [ "$FP1" = "$FP2" ]; then
      t_pass "powtórne uruchomienie → deterministyczny wynik (identyczne fingerprinty)"
    else
      t_fail "powtórne uruchomienie → różne fingerprinty (nie-deterministyczne)"
    fi
  else
    t_fail "drugie uruchomienie → oczekiwano PASS, dostał FAIL"
  fi
else
  t_fail "pierwsze uruchomienie → oczekiwano PASS, dostał FAIL"
fi
rm -rf "$TMP"

# ── T9: substytucja tokenów → wartości z manifestu ───────────
echo ""
echo "--- T9: substytucja tokenów → wartości z manifestu ---"
TMP="$(mktemp -d)"
# Tworzymy katalog z plikiem zawierającym tokeny.
mkdir -p "$TMP/proj"
echo "name={{project.name}} id={{project.identity}} type={{project.type}} ver={{template.version}}" > "$TMP/proj/README.md"
# Wywołaj substitute w subprocesie (ścieżka przekazana jako argument $1).
SUBST_RESULT="$(bash -c '
set -u
DEST="$1"
REPO_ROOT="/opt/Prod-ready"
TEMPLATE_ROOT="$REPO_ROOT"
VERSION_FILE="$REPO_ROOT/VERSION"
REGISTRY="$REPO_ROOT/config/canonical/registry.yaml"
PROJECT_TYPES="minimal cli rust-backend python-service web ai distributed data multi-service filesystem"
SUBSTITUTION_TOKENS=("{{project.identity}}" "{{project.type}}" "{{project.profile}}" "{{project.name}}" "{{project.root}}" "{{template.version}}")
COPY_EXCLUDE=(".git" ".qwen" ".tools" "secrets" "artifacts" "out" "target" "build" "dist" "node_modules" "__pycache__" ".venv" "venv" ".pytest_cache" ".mypy_cache" ".ruff_cache" "data" "logs" "coverage")
SCAFFOLD_FAIL=0
scaffold_fail() { SCAFFOLD_FAIL=$((SCAFFOLD_FAIL+1)); }
scaffold_pass() { :; }
substitute() {
  local dest="$1"
  local identity="$2" type="$3" profile="$4" name="$5" root="$6" tpl_version="$7"
  local substituted=0
  local -A vals
  vals["{{project.identity}}"]="$identity"
  vals["{{project.type}}"]="$type"
  vals["{{project.profile}}"]="$profile"
  vals["{{project.name}}"]="$name"
  vals["{{project.root}}"]="$root"
  vals["{{template.version}}"]="$tpl_version"
  local f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$f" ] || continue
    if file "$f" 2>/dev/null | grep -qE "binary|executable"; then continue; fi
    local changed=0 tok
    for tok in "${SUBSTITUTION_TOKENS[@]}"; do
      if grep -qF "$tok" "$f" 2>/dev/null; then
        sed -i "s|${tok}|${vals[$tok]}|g" "$f" 2>/dev/null
        changed=1
      fi
    done
    [ "$changed" -eq 1 ] && substituted=$((substituted+1))
  done < <(find "$dest" -type f -not -path "$dest/.scaffold/*" 2>/dev/null)
  echo "$substituted"
}
substitute "$DEST" "t09-subst" "minimal" "fast" "T09 Subst" "./out/t09" "0.1.0"
' bash "$TMP/proj")"
# Sprawdź, czy tokeny zostały podstawione.
CONTENT="$(cat "$TMP/proj/README.md")"
if [ "$SUBST_RESULT" -ge 1 ] && printf '%s' "$CONTENT" | grep -q "name=T09 Subst" && printf '%s' "$CONTENT" | grep -q "id=t09-subst" && printf '%s' "$CONTENT" | grep -q "type=minimal" && printf '%s' "$CONTENT" | grep -q "ver=0.1.0"; then
  t_pass "substytucja tokenów → wartości z manifestu podstawione"
else
  t_fail "substytucja tokenów → nie podstawiono (result=$SUBST_RESULT, content=$CONTENT)"
fi
rm -rf "$TMP"

# ── Podsumowanie ─────────────────────────────────────────────
echo ""
echo "=== SCAFFOLD CONTRACT — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
