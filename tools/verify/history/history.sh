#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# history/history.sh — AIGON Production Platform — Reconciliation Engine
# Moduł: HISTORY RECONCILIATION (warstwa HISTORY)
# Wykrywa legacy / deprecated / archived / migrations / stale refs.
#
# Model 4 warstw:
#   HISTORY — legacy / deprecated / archived / migrations / stale refs
#
# Poziomy:
#   L4 HISTORY — legacy/deprecated/archived/migrations/stale refs
#
# Checki:
#   HIST-001  Archive struktura (archive/2025, 2026, legacy, quarantine, cemetery)
#   HIST-002  Archive README (każdy katalog archive ma README)
#   HIST-003  Migracje (MIGRATION.md istnieje i ma STATUS)
#   HIST-004  Stale refs (odwołania do nieistniejących plików/katalogów)
#   HIST-005  Deprecated markery (DEPRECATED w docs)
#   HIST-006  CHANGELOG aktualny (ostatni wpis = bieżąca wersja)
#   HIST-007  VERSION zgodny z CHANGELOG
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"
# shellcheck source=../core/reconcile.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/reconcile.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== HISTORY RECONCILIATION (L4 HISTORY) ==="

# ── HIST-001 Archive struktura ──────────────────────────────
say ""
say "--- L4 HISTORY: Archive struktura ---"
if [ -d "./archive" ]; then
  # Oczekiwane katalogi archive
  EXPECTED_ARCHIVE=("2025" "2026" "legacy" "quarantine" "cemetery")
  MISSING_ARCHIVE=""
  for d in "${EXPECTED_ARCHIVE[@]}"; do
    if [ ! -d "./archive/$d" ]; then
      MISSING_ARCHIVE="$MISSING_ARCHIVE $d"
    fi
  done
  if [ -n "$MISSING_ARCHIVE" ]; then
    info "HIST-001 Archive struktura" "Brak oczekiwanych katalogów archive:$MISSING_ARCHIVE"
  else
    pass "HIST-001 Archive struktura" BLOCKING "Archive ma pełną strukturę (2025/2026/legacy/quarantine/cemetery)."
  fi
else
  fail "HIST-001 Archive struktura" BLOCKING "Brak katalogu archive/."
fi

# ── HIST-002 Archive README ─────────────────────────────────
say ""
say "--- L4 HISTORY: Archive README ---"
if [ -d "./archive" ]; then
  MISSING_README=0
  while IFS= read -r d; do
    if [ ! -f "$d/README.md" ]; then
      MISSING_README=$((MISSING_README+1))
    fi
  done < <(find ./archive -type d -not -path './archive/.git/*' 2>/dev/null)
  if [ "$MISSING_README" -eq 0 ]; then
    pass "HIST-002 Archive README" BLOCKING "Każdy katalog archive ma README."
  else
    warn "HIST-002 Archive README" "$MISSING_README katalogów archive bez README."
  fi
else
  info "HIST-002 Archive README" "Brak katalogu archive/."
fi

# ── HIST-003 Migracje ───────────────────────────────────────
say ""
say "--- L4 HISTORY: Migracje ---"
if [ -f "./MIGRATION.md" ]; then
  mig_status=$(grep -E 'STATUS:' ./MIGRATION.md | head -1 | sed 's/.*STATUS:[[:space:]]*//')
  if [ -z "$mig_status" ] || [ "$mig_status" = "UNDEFINED" ]; then
    warn "HIST-003 Migracje" "MIGRATION.md ma STATUS: $mig_status — wymaga decyzji."
  else
    pass "HIST-003 Migracje" BLOCKING "MIGRATION.md STATUS: $mig_status"
  fi
else
  info "HIST-003 Migracje" "Brak MIGRATION.md (repo foundation, brak migracji)."
fi

# ── HIST-004 Stale refs ─────────────────────────────────────
say ""
say "--- L4 HISTORY: Stale refs ---"
# Odwołania w docs do nieistniejących plików/katalogów.
STALE=0
STALE_DETAIL=""
while IFS= read -r f; do
  [ "$f" = "./README.md" ] && continue
  # Szukamy odwołań do ścieżek w formacie ./katalog/ lub katalog/
  while IFS= read -r ref; do
    # Wyciągnij ścieżkę (pierwszy token po ./ lub /)
    path=$(echo "$ref" | grep -oE '\./[A-Za-z0-9_./-]+' | head -1)
    [ -z "$path" ] && continue
    # Usuń trailing slash i fragmenty
    target="${path#./}"
    target="${target%%/*}"
    # Pomiń znane katalogi i pliki
    case "$target" in
      ""|git|github|tools|docs|archive|config|deployment|agents|apps|business|contracts|data|filesystem|governance|mesh|models|observability|operations|secrets|security|shared|system|tests|artifacts|README.md|CHANGELOG.md|VERSION|CODEOWNERS|LICENSE|SOURCE-OF-TRUTH.md|OWNERSHIP.md|ARCHITECTURE.md|DEPLOYMENT.md|MIGRATION.md|RECOVERY.md|CONTRIBUTING.md|SECURITY.md|KANON.md|MAP.md|AGENTS.md|QWEN.md|stack.yaml|deploy.sh)
      continue ;;
    esac
    # Sprawdź czy istnieje
    if [ ! -e "./$target" ]; then
      STALE=$((STALE+1))
      STALE_DETAIL="$STALE_DETAIL [$target] w $f"
    fi
  done < <(grep -oE '\./[A-Za-z0-9_./-]+' "$f" 2>/dev/null | sort -u)
done < <(find . -name '*.md' -not -path './.git/*' -not -path './tools/verify/*' 2>/dev/null)

if [ "$STALE" -eq 0 ]; then
  pass "HIST-004 Stale refs" BLOCKING "Brak odwołań do nieistniejących ścieżek."
else
  warn "HIST-004 Stale refs" "$STALE stale refs: $STALE_DETAIL"
fi

# ── HIST-005 Deprecated markery ─────────────────────────────
say ""
say "--- L4 HISTORY: Deprecated markery ---"
DEPRECATED=$(grep -rniE 'DEPRECATED|deprecated|legacy|przestarza' \
  --include='*.md' --include='*.sh' --include='*.yml' --include='*.yaml' \
  . 2>/dev/null \
  | grep -vE './.git/|./tools/verify/|./archive/' \
  | head -10)
if [ -n "$DEPRECATED" ]; then
  info "HIST-005 Deprecated markery" "Znaleziono markery deprecated: $DEPRECATED"
else
  pass "HIST-005 Deprecated markery" BLOCKING "Brak markerów deprecated."
fi

# ── HIST-006 CHANGELOG aktualny ─────────────────────────────
say ""
say "--- L4 HISTORY: CHANGELOG ---"
if [ -f "./CHANGELOG.md" ]; then
  version=$(cat ./VERSION 2>/dev/null | tr -d '[:space:]')
  if grep -qE "$version" ./CHANGELOG.md; then
    pass "HIST-006 CHANGELOG aktualny" BLOCKING "CHANGELOG zawiera wersję $version."
  else
    warn "HIST-006 CHANGELOG aktualny" "CHANGELOG nie zawiera bieżącej wersji $version."
  fi
else
  fail "HIST-006 CHANGELOG aktualny" BLOCKING "Brak CHANGELOG.md."
fi

# ── HIST-007 VERSION zgodny z CHANGELOG ─────────────────────
say ""
say "--- L4 HISTORY: VERSION ---"
if [ -f "./VERSION" ]; then
  version=$(cat ./VERSION 2>/dev/null | tr -d '[:space:]')
  if [ -n "$version" ]; then
    pass "HIST-007 VERSION" BLOCKING "VERSION: $version"
  else
    fail "HIST-007 VERSION" BLOCKING "VERSION jest pusty."
  fi
else
  fail "HIST-007 VERSION" BLOCKING "Brak VERSION."
fi

say ""
