#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/performance.sh — GATE-015 PERFORMANCE
# Weryfikuje progi wydajności.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-015 PERFORMANCE ==="

# ── PERFORMANCE-001: brak dużych plików binarnych w repo ────
# Pliki > 10MB w repo (poza .git) — podejrzane.
LARGE_FILES=0
LARGE_DETAIL=""
while IFS= read -r f; do
  size=$(stat -c%s "$f" 2>/dev/null || echo 0)
  if [ "$size" -gt 10485760 ]; then
    LARGE_FILES=$((LARGE_FILES+1))
    LARGE_DETAIL="$LARGE_DETAIL $f($size)"
  fi
done < <(find . -type f -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null)

if [ "$LARGE_FILES" -eq 0 ]; then
  pass "PERFORMANCE-001 brak dużych plików" BLOCKING "Brak plików > 10MB."
else
  warn "PERFORMANCE-001 brak dużych plików" "$LARGE_FILES dużych plików:$LARGE_DETAIL"
fi

# ── PERFORMANCE-002: brak ogromnych plików tekstowych ───────
# Pliki tekstowe > 5MB — podejrzane (dumpy, logi).
HUGE_TEXT=0
HUGE_DETAIL=""
while IFS= read -r f; do
  case "$f" in
    *.md|*.txt|*.log|*.json) ;;
    *) continue ;;
  esac
  size=$(stat -c%s "$f" 2>/dev/null || echo 0)
  if [ "$size" -gt 5242880 ]; then
    HUGE_TEXT=$((HUGE_TEXT+1))
    HUGE_DETAIL="$HUGE_DETAIL $f($size)"
  fi
done < <(find . -type f -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null)

if [ "$HUGE_TEXT" -eq 0 ]; then
  pass "PERFORMANCE-002 brak ogromnych plików tekstowych" BLOCKING "Brak plików tekstowych > 5MB."
else
  warn "PERFORMANCE-002 brak ogromnych plików tekstowych" "$HUGE_TEXT ogromnych plików:$HUGE_DETAIL"
fi

verify_module_exit
