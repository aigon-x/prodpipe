#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# git/history.sh — AIGON Production Platform — Repository Certification Engine
# Moduł: GIT HISTORY QUALITY
# Wykrywa problemy w historii git.
#
# Checki:
#   GIT-101  No huge commits (informational)
#   GIT-102  No binary blobs (informational)
#   GIT-103  No secrets in history (delegated to security)
#   GIT-104  No generated state commits (informational)
#   GIT-105  No mass unrelated changes (informational)
#   GIT-106  No merge bombs (informational)
#   GIT-107  No suspicious force pushes (informational)
#   GIT-108  Commit message quality (informational)
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GIT HISTORY QUALITY ==="

# GIT-101 No huge commits (informational)
# Commit z > 500 plików lub > 50MB zmian.
HUGE=$(git log --all --pretty=format:'%H %s' --numstat 2>/dev/null | awk '
  /^[0-9a-f]{40}/ { commit=$0; files=0; next }
  /^[0-9-]+\t[0-9-]+\t/ { files++ }
  /^$/ { if (files > 500) print commit " (" files " files)"; files=0 }
' | head -5)
if [ -n "$HUGE" ]; then
  info "GIT-101 No huge commits" "Ogromne commity: $HUGE"
else
  pass "GIT-101 No huge commits"
fi

# GIT-102 No binary blobs (informational)
BINARY=$(git log --all --pretty=format:'%H' --name-only 2>/dev/null | grep -E '\.(png|jpg|jpeg|gif|pdf|zip|tar|gz|bin|exe|dll|so|dylib|class|jar|war|ear|o|a)$' | sort -u | head -5)
if [ -n "$BINARY" ]; then
  info "GIT-102 No binary blobs" "Binaria w historii: $BINARY"
else
  pass "GIT-102 No binary blobs"
fi

# GIT-103 No secrets in history (delegated to security module)
# Pełny scan historii robi moduł security/history.sh.
info "GIT-103 No secrets in history" "Delegowane do modułu security/history.sh."

# GIT-104 No generated state commits (informational)
# Commity zawierające target/, node_modules/, dist/, build/.
GEN=$(git log --all --pretty=format:'%H %s' --name-only 2>/dev/null | grep -E '(^|/)(target|node_modules|dist|build|\.cache)/' | head -5)
if [ -n "$GEN" ]; then
  info "GIT-104 No generated state commits" "Commity ze stanem wygenerowanym: $GEN"
else
  pass "GIT-104 No generated state commits"
fi

# GIT-105 No mass unrelated changes (informational)
# Commit zmieniający pliki w > 5 różnych top-level katalogach.
MASS=$(git log --all --pretty=format:'%H %s' --name-only 2>/dev/null | awk '
  /^[0-9a-f]{40}/ { commit=$0; dirs=""; next }
  /^\t/ { d=$1; sub(/\/.*/, "", d); if (dirs !~ d) dirs=dirs " " d }
  /^$/ { n=split(dirs, a, " "); if (n > 5) print commit " (" n " dirs)"; dirs="" }
' | head -5)
if [ -n "$MASS" ]; then
  info "GIT-105 No mass unrelated changes" "Commity z masowymi zmianami: $MASS"
else
  pass "GIT-105 No mass unrelated changes"
fi

# GIT-106 No merge bombs (informational)
# Merge z > 20 parentów (octopus merge).
MERGEBOMB=$(git log --all --merges --pretty=format:'%H %P' 2>/dev/null | awk 'NF > 21 {print $1 " (" NF-1 " parents)"}' | head -5)
if [ -n "$MERGEBOMB" ]; then
  info "GIT-106 No merge bombs" "Merge bomby: $MERGEBOMB"
else
  pass "GIT-106 No merge bombs"
fi

# GIT-107 No suspicious force pushes (informational)
# Nie można wykryć force push z lokalnego repo bez reflog — informacyjnie.
info "GIT-107 No suspicious force pushes" "Force push nie jest wykrywalny lokalnie — sprawdź reflog i remote."

# GIT-108 Commit message quality (informational)
# Sprawdzamy czy commity używają dozwolonych typów.
FORBIDDEN=$(git log --all --pretty=format:'%s' 2>/dev/null | grep -E '^(misc|stuff|changes|update|final|final2|important|fix-all)(\s|:|$)' | head -5)
if [ -n "$FORBIDDEN" ]; then
  info "GIT-108 Commit message quality" "Zakazane typy commitów: $FORBIDDEN"
else
  pass "GIT-108 Commit message quality"
fi

verify_module_exit
