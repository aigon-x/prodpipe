#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-029 — BUILD (Build script presence)
# Rodzina: BUILD | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje, że repo posiada zdefiniowany skrypt budowy
# (Makefile, build.sh, Dockerfile, package.json z build script,
# lub workflow CI z krokiem build). Wykrywa brak skryptu budowy.
#
# Wykrywa:
#   * NO-BUILD-SCRIPT — brak jakiegokolwiek skryptu budowy w repo
#
# Pipeline Contract: DISCOVER → CONTRACT → EXECUTE → TEST → EVIDENCE → VERIFY → REGISTER → REPORT
# Dual Verdict: IMPLEMENTATION (czy pipeline jest poprawnie zbudowany) vs REPOSITORY (czy repo spełnia kontrakt)
# ─────────────────────────────────────────────────────────────
set -u

# ── Wczytaj core ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
. "$AUTOMATION_DIR/core/lib.sh"
. "$AUTOMATION_DIR/core/pipelines.sh"

ROOT="$(p_root)"
cd "$ROOT"

# ── DISCOVER ────────────────────────────────────────────────
p_say "=== P-029 BUILD ==="
p_say "Weryfikacja obecności skryptu budowy w repo"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-029"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywamy skrypt budowy w repo (git-tracked). Uznajemy za skrypt budowy:
#   * Makefile / makefile / GNUmakefile
#   * build.sh / build (skrypt)
#   * Dockerfile / *.dockerfile
#   * package.json z sekcją "scripts.build"
#   * workflow CI (.github/workflows/*.yml) z krokiem build
HAS_BUILD=0
BUILD_SOURCES=""

# 1. Makefile
if git ls-files | grep -qE '(^|/)(Makefile|makefile|GNUmakefile)$'; then
  HAS_BUILD=1
  BUILD_SOURCES="$BUILD_SOURCES Makefile"
fi

# 2. build.sh / build
if git ls-files | grep -qE '(^|/)build\.sh$'; then
  HAS_BUILD=1
  BUILD_SOURCES="$BUILD_SOURCES build.sh"
fi

# 3. Dockerfile
if git ls-files | grep -qiE '(^|/)Dockerfile(\.|$)|\.dockerfile$'; then
  HAS_BUILD=1
  BUILD_SOURCES="$BUILD_SOURCES Dockerfile"
fi

# 4. package.json z build script
if git ls-files | grep -qE '(^|/)package\.json$'; then
  if command -v node >/dev/null 2>&1; then
    if node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts.build ? 0 : 1)" 2>/dev/null; then
      HAS_BUILD=1
      BUILD_SOURCES="$BUILD_SOURCES package.json(build)"
    fi
  else
    # best-effort: grep na surowym JSON
    if grep -qE '"build"\s*:' package.json 2>/dev/null; then
      HAS_BUILD=1
      BUILD_SOURCES="$BUILD_SOURCES package.json(build)"
    fi
  fi
fi

# 5. Workflow CI z krokiem build
if git ls-files '.github/workflows/*.yml' '.github/workflows/*.yaml' 2>/dev/null | grep -q .; then
  if git ls-files '.github/workflows/*.yml' '.github/workflows/*.yaml' 2>/dev/null | xargs grep -lE 'run:.*(build|make|npm run build|docker build)' 2>/dev/null | grep -q .; then
    HAS_BUILD=1
    BUILD_SOURCES="$BUILD_SOURCES .github/workflows(build)"
  fi
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$HAS_BUILD" -eq 1 ]; then
  p_pass "BUILD-SCRIPT-PRESENT" BLOCKING "Znaleziono skrypt budowy:$BUILD_SOURCES"
else
  p_fail "BUILD-NO-SCRIPT" BLOCKING "Brak skryptu budowy w repo (Makefile/build.sh/Dockerfile/package.json build/workflow CI build)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-029:build HAS_BUILD=$HAS_BUILD SOURCES=$BUILD_SOURCES" "pipeline" "build/build.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$HAS_BUILD" -eq 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-029" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-029" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
