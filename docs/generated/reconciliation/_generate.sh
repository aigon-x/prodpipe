#!/usr/bin/env bash
# ============================================================================
# _generate.sh — OPERATION RECONCILE ZERO (R2) — generator grafów
# Generuje 9 plików JSON + reconciliation-report.md w docs/generated/reconciliation/
# Uruchom: bash docs/generated/reconciliation/_generate.sh
# ============================================================================
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
OUT="$(pwd)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$OUT/../../..")"

# ── Pomocnicze ──────────────────────────────────────────────
# join: wypisuje elementy z przecinkami (bez trailing comma)
join() { local first=1; while IFS= read -r line; do [ -z "$line" ] && continue; if [ $first -eq 1 ]; then printf '%s' "$line"; first=0; else printf ',\n%s' "$line"; fi; done; printf '\n'; }

# ── 1. repository-inventory.json ────────────────────────────
{
  echo '{'
  echo '  "generated_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
  echo '  "operation": "OPERATION RECONCILE ZERO",'
  echo '  "phase": "R2",'
  echo '  "branch": "'$(git branch --show-current 2>/dev/null)'",'
  echo '  "commit": "'$(git rev-parse --short HEAD 2>/dev/null)'",'
  echo '  "tag": "'$(git describe --tags 2>/dev/null || echo "none")'",'
  echo '  "file_count": '$(find "$ROOT" -type f -not -path '*/.git/*' | wc -l)','
  echo '  "dir_count": '$(find "$ROOT" -type d -not -path '*/.git/*' | wc -l)','
  echo '  "top_level_dirs": ['
  find "$ROOT" -maxdepth 1 -type d -not -path "$ROOT" -not -name '.git' | sort | while read -r d; do
    b="$(basename "$d")"
    n=$(find "$d" -type f | wc -l)
    echo "    {\"name\": \"$b\", \"files\": $n}"
  done | join
  echo '  ],'
  echo '  "executable_scripts": ['
  find "$ROOT" -type f -name '*.sh' -not -path '*/.git/*' | sort | while read -r f; do
    echo "    \"${f#$ROOT/}\""
  done | join
  echo '  ]'
  echo '}'
} > "$OUT/repository-inventory.json"

# ── 2. repository-graph.json ────────────────────────────────
{
  echo '{'
  echo '  "type": "repository-graph",'
  echo '  "nodes": ['
  echo '    {"id":"root","type":"dir","path":"/"},'
  find "$ROOT" -maxdepth 1 -type d -not -path "$ROOT" -not -name '.git' | sort | while read -r d; do
    b="$(basename "$d")"
    echo "    {\"id\":\"$b\",\"type\":\"dir\",\"path\":\"/$b\"}"
  done | join
  echo '  ],'
  echo '  "edges": ['
  find "$ROOT" -maxdepth 1 -type d -not -path "$ROOT" -not -name '.git' | sort | while read -r d; do
    b="$(basename "$d")"
    echo "    {\"from\":\"root\",\"to\":\"$b\",\"relation\":\"contains\"}"
  done | join
  echo '  ]'
  echo '}'
} > "$OUT/repository-graph.json"

# ── 3. dependency-graph.json ────────────────────────────────
{
  echo '{'
  echo '  "type": "dependency-graph",'
  echo '  "description": "Zależności między modułami weryfikacji i stanu",'
  echo '  "nodes": ['
  echo '    {"id":"verify.sh","type":"entrypoint","path":"tools/verify/verify.sh"},'
  echo '    {"id":"lib.sh","type":"core","path":"tools/verify/core/lib.sh"},'
  echo '    {"id":"profiles.sh","type":"core","path":"tools/verify/core/profiles.sh"},'
  echo '    {"id":"report.sh","type":"core","path":"tools/verify/core/report.sh"},'
  echo '    {"id":"reconcile.sh","type":"core","path":"tools/verify/core/reconcile.sh"},'
  echo '    {"id":"baseline.sh","type":"module","path":"tools/verify/reconcile/baseline.sh"},'
  echo '    {"id":"reconcile-mod.sh","type":"module","path":"tools/verify/reconcile/reconcile.sh"},'
  echo '    {"id":"drift.sh","type":"module","path":"tools/verify/drift/drift.sh"},'
  echo '    {"id":"history.sh","type":"module","path":"tools/verify/history/history.sh"},'
  echo '    {"id":"scanner.sh","type":"module","path":"tools/verify/debt/scanner.sh"},'
  echo '    {"id":"debt.sh","type":"module","path":"tools/verify/debt/debt.sh"},'
  echo '    {"id":"git-integrity","type":"module","path":"tools/verify/git/integrity.sh"},'
  echo '    {"id":"git-branches","type":"module","path":"tools/verify/git/branches.sh"},'
  echo '    {"id":"git-history","type":"module","path":"tools/verify/git/history.sh"},'
  echo '    {"id":"git-tags","type":"module","path":"tools/verify/git/tags.sh"},'
  echo '    {"id":"sec-secrets","type":"module","path":"tools/verify/security/secrets.sh"},'
  echo '    {"id":"sec-credentials","type":"module","path":"tools/verify/security/credentials.sh"},'
  echo '    {"id":"sec-history","type":"module","path":"tools/verify/security/history.sh"},'
  echo '    {"id":"str-readme","type":"module","path":"tools/verify/structure/readme.sh"},'
  echo '    {"id":"state.sh","type":"state","path":"system/control-plane/state/state.sh"},'
  echo '    {"id":"state-lib.sh","type":"state","path":"system/control-plane/state/lib.sh"},'
  echo '    {"id":"repo-integrity","type":"tool","path":"tools/repository-integrity.sh"},'
  echo '    {"id":"secret-scan","type":"tool","path":"tools/security/secret-scan.sh"}'
  echo '  ],'
  echo '  "edges": ['
  echo '    {"from":"verify.sh","to":"lib.sh","relation":"sources"},'
  echo '    {"from":"verify.sh","to":"profiles.sh","relation":"sources"},'
  echo '    {"from":"verify.sh","to":"report.sh","relation":"sources"},'
  echo '    {"from":"verify.sh","to":"reconcile.sh","relation":"sources"},'
  echo '    {"from":"verify.sh","to":"baseline.sh","relation":"runs"},'
  echo '    {"from":"verify.sh","to":"reconcile-mod.sh","relation":"runs"},'
  echo '    {"from":"verify.sh","to":"drift.sh","relation":"runs"},'
  echo '    {"from":"verify.sh","to":"history.sh","relation":"runs"},'
  echo '    {"from":"verify.sh","to":"scanner.sh","relation":"runs"},'
  echo '    {"from":"verify.sh","to":"debt.sh","relation":"runs"},'
  echo '    {"from":"scanner.sh","to":"lib.sh","relation":"sources"},'
  echo '    {"from":"scanner.sh","to":"reconcile.sh","relation":"sources"},'
  echo '    {"from":"git-integrity","to":"lib.sh","relation":"sources"},'
  echo '    {"from":"git-branches","to":"lib.sh","relation":"sources"},'
  echo '    {"from":"git-history","to":"lib.sh","relation":"sources"},'
  echo '    {"from":"git-tags","to":"lib.sh","relation":"sources"},'
  echo '    {"from":"sec-secrets","to":"lib.sh","relation":"sources"},'
  echo '    {"from":"sec-secrets","to":"secret-scan","relation":"delegates"},'
  echo '    {"from":"sec-credentials","to":"lib.sh","relation":"sources"},'
  echo '    {"from":"sec-history","to":"lib.sh","relation":"sources"},'
  echo '    {"from":"str-readme","to":"lib.sh","relation":"sources"},'
  echo '    {"from":"state.sh","to":"state-lib.sh","relation":"sources"},'
  echo '    {"from":"repo-integrity","to":"lib.sh","relation":"sources"}'
  echo '  ]'
  echo '}'
} > "$OUT/dependency-graph.json"

# ── 4. execution-graph.json ─────────────────────────────────
{
  echo '{'
  echo '  "type": "execution-graph",'
  echo '  "description": "Kolejność wykonywania modułów w verify.sh reconcile",'
  echo '  "entrypoint": "tools/verify/verify.sh",'
  echo '  "subcommand": "reconcile",'
  echo '  "sequence": ['
  echo '    {"order":1,"module":"reconcile/baseline.sh","layer":"CANON"},'
  echo '    {"order":2,"module":"reconcile/reconcile.sh","layer":"CANON"},'
  echo '    {"order":3,"module":"drift/drift.sh","layer":"DRIFT"},'
  echo '    {"order":4,"module":"history/history.sh","layer":"HISTORY"},'
  echo '    {"order":5,"module":"debt/scanner.sh","layer":"DEBT"},'
  echo '    {"order":6,"module":"debt/debt.sh","layer":"DEBT"}'
  echo '  ],'
  echo '  "orphaned_modules_not_executed": ['
  echo '    "tools/verify/git/integrity.sh",'
  echo '    "tools/verify/git/branches.sh",'
  echo '    "tools/verify/git/history.sh",'
  echo '    "tools/verify/git/tags.sh",'
  echo '    "tools/verify/security/secrets.sh",'
  echo '    "tools/verify/security/credentials.sh",'
  echo '    "tools/verify/security/history.sh",'
  echo '    "tools/verify/structure/readme.sh"'
  echo '  ]'
  echo '}'
} > "$OUT/execution-graph.json"

# ── 5. config-graph.json ────────────────────────────────────
{
  echo '{'
  echo '  "type": "config-graph",'
  echo '  "description": "Konfiguracja i pliki stanu",'
  echo '  "nodes": ['
  echo '    {"id":"config","type":"dir","path":"config/"},'
  echo '    {"id":"config-canonical","type":"dir","path":"config/canonical/"},'
  echo '    {"id":"config-generated","type":"dir","path":"config/generated/"},'
  echo '    {"id":"config-local","type":"dir","path":"config/local/"},'
  echo '    {"id":"config-schemas","type":"dir","path":"config/schemas/"},'
  echo '    {"id":"config-templates","type":"dir","path":"config/templates/"},'
  echo '    {"id":"state","type":"state","path":"system/control-plane/state/"},'
  echo '    {"id":"state-db","type":"state","path":"system/control-plane/state/data/"},'
  echo '    {"id":"state-migrations","type":"state","path":"system/control-plane/state/migrations/"},'
  echo '    {"id":"state-schema","type":"state","path":"system/control-plane/state/schema.sql"},'
  echo '    {"id":"git-hooks","type":"config","path":".git-hooks/"},'
  echo '    {"id":"gitattributes","type":"config","path":".gitattributes"},'
  echo '    {"id":"gitignore","type":"config","path":".gitignore"},'
  echo '    {"id":"gitmessage","type":"config","path":".gitmessage"}'
  echo '  ],'
  echo '  "edges": ['
  echo '    {"from":"config","to":"config-canonical","relation":"contains"},'
  echo '    {"from":"config","to":"config-generated","relation":"contains"},'
  echo '    {"from":"config","to":"config-local","relation":"contains"},'
  echo '    {"from":"config","to":"config-schemas","relation":"contains"},'
  echo '    {"from":"config","to":"config-templates","relation":"contains"},'
  echo '    {"from":"state","to":"state-db","relation":"contains"},'
  echo '    {"from":"state","to":"state-migrations","relation":"contains"},'
  echo '    {"from":"state","to":"state-schema","relation":"contains"}'
  echo '  ]'
  echo '}'
} > "$OUT/config-graph.json"

# ── 6. documentation-graph.json ─────────────────────────────
{
  echo '{'
  echo '  "type": "documentation-graph",'
  echo '  "description": "Struktura dokumentacji",'
  echo '  "nodes": ['
  echo '    {"id":"docs","type":"dir","path":"docs/"},'
  echo '    {"id":"docs-foundation","type":"dir","path":"docs/00-foundation/"},'
  echo '    {"id":"docs-arch","type":"dir","path":"docs/architecture/"},'
  echo '    {"id":"docs-decisions","type":"dir","path":"docs/decisions/"},'
  echo '    {"id":"docs-dev","type":"dir","path":"docs/development/"},'
  echo '    {"id":"docs-git","type":"dir","path":"docs/git/"},'
  echo '    {"id":"docs-ops","type":"dir","path":"docs/operations/"},'
  echo '    {"id":"docs-ref","type":"dir","path":"docs/reference/"},'
  echo '    {"id":"docs-sec","type":"dir","path":"docs/security/"},'
  echo '    {"id":"docs-user","type":"dir","path":"docs/user/"},'
  echo '    {"id":"docs-generated","type":"dir","path":"docs/generated/reconciliation/"},'
  echo '    {"id":"README","type":"file","path":"README.md"},'
  echo '    {"id":"ARCHITECTURE","type":"file","path":"ARCHITECTURE.md"},'
  echo '    {"id":"SOURCE-OF-TRUTH","type":"file","path":"SOURCE-OF-TRUTH.md"},'
  echo '    {"id":"OWNERSHIP","type":"file","path":"OWNERSHIP.md"}'
  echo '  ],'
  echo '  "edges": ['
  echo '    {"from":"docs","to":"docs-foundation","relation":"contains"},'
  echo '    {"from":"docs","to":"docs-arch","relation":"contains"},'
  echo '    {"from":"docs","to":"docs-decisions","relation":"contains"},'
  echo '    {"from":"docs","to":"docs-dev","relation":"contains"},'
  echo '    {"from":"docs","to":"docs-git","relation":"contains"},'
  echo '    {"from":"docs","to":"docs-ops","relation":"contains"},'
  echo '    {"from":"docs","to":"docs-ref","relation":"contains"},'
  echo '    {"from":"docs","to":"docs-sec","relation":"contains"},'
  echo '    {"from":"docs","to":"docs-user","relation":"contains"},'
  echo '    {"from":"docs","to":"docs-generated","relation":"contains"}'
  echo '  ]'
  echo '}'
} > "$OUT/documentation-graph.json"

# ── 7. test-graph.json ──────────────────────────────────────
{
  echo '{'
  echo '  "type": "test-graph",'
  echo '  "description": "Struktura testów",'
  echo '  "nodes": ['
  echo '    {"id":"tests","type":"dir","path":"tests/"},'
  echo '    {"id":"tests-chaos","type":"dir","path":"tests/chaos/"},'
  echo '    {"id":"tests-contract","type":"dir","path":"tests/contract/"},'
  echo '    {"id":"tests-e2e","type":"dir","path":"tests/e2e/"},'
  echo '    {"id":"tests-fixtures","type":"dir","path":"tests/fixtures/"},'
  echo '    {"id":"tests-integration","type":"dir","path":"tests/integration/"},'
  echo '    {"id":"tests-performance","type":"dir","path":"tests/performance/"},'
  echo '    {"id":"tests-regression","type":"dir","path":"tests/regression/"},'
  echo '    {"id":"tests-security","type":"dir","path":"tests/security/"},'
  echo '    {"id":"tests-unit","type":"dir","path":"tests/unit/"},'
  echo '    {"id":"test-state","type":"test","path":"system/control-plane/state/tests/test_state.sh"}'
  echo '  ],'
  echo '  "edges": ['
  echo '    {"from":"tests","to":"tests-chaos","relation":"contains"},'
  echo '    {"from":"tests","to":"tests-contract","relation":"contains"},'
  echo '    {"from":"tests","to":"tests-e2e","relation":"contains"},'
  echo '    {"from":"tests","to":"tests-fixtures","relation":"contains"},'
  echo '    {"from":"tests","to":"tests-integration","relation":"contains"},'
  echo '    {"from":"tests","to":"tests-performance","relation":"contains"},'
  echo '    {"from":"tests","to":"tests-regression","relation":"contains"},'
  echo '    {"from":"tests","to":"tests-security","relation":"contains"},'
  echo '    {"from":"tests","to":"tests-unit","relation":"contains"}'
  echo '  ]'
  echo '}'
} > "$OUT/test-graph.json"

# ── 8. gate-graph.json ──────────────────────────────────────
{
  echo '{'
  echo '  "type": "gate-graph",'
  echo '  "description": "Bramy jakości (gates) i ich stan",'
  echo '  "gates": ['
  echo '    {"id":"GIT-001..019","module":"git/integrity.sh","status":"ORPHANED","gate":"FALSE GATE (say \"\")"},'
  echo '    {"id":"GIT-201..203","module":"git/branches.sh","status":"ORPHANED","gate":"FALSE GATE (say \"\")"},'
  echo '    {"id":"GIT-101..108","module":"git/history.sh","status":"ORPHANED","gate":"FALSE GATE (say \"\")"},'
  echo '    {"id":"GIT-301..303","module":"git/tags.sh","status":"ORPHANED","gate":"FALSE GATE (say \"\")"},'
  echo '    {"id":"SEC-001..004","module":"security/secrets.sh","status":"ORPHANED","gate":"FALSE GATE (say \"\")"},'
  echo '    {"id":"SEC-201..208","module":"security/credentials.sh","status":"ORPHANED","gate":"FALSE GATE (say \"\")"},'
  echo '    {"id":"SEC-101..102","module":"security/history.sh","status":"ORPHANED","gate":"FALSE GATE (say \"\")"},'
  echo '    {"id":"STR-001..003","module":"structure/readme.sh","status":"ORPHANED","gate":"FALSE GATE (say \"\")"},'
  echo '    {"id":"BASE-001..006","module":"reconcile/baseline.sh","status":"CONNECTED","gate":"verify_module_exit"},'
  echo '    {"id":"DRIFT-001..009","module":"drift/drift.sh","status":"CONNECTED","gate":"verify_module_exit"},'
  echo '    {"id":"HIST-001..007","module":"history/history.sh","status":"CONNECTED","gate":"verify_module_exit"},'
  echo '    {"id":"DEBT-001..014","module":"debt/scanner.sh","status":"CONNECTED","gate":"verify_module_exit"},'
  echo '    {"id":"DEBT-101..106","module":"debt/debt.sh","status":"CONNECTED","gate":"verify_module_exit"}'
  echo '  ]'
  echo '}'
} > "$OUT/gate-graph.json"

# ── 9. workflow-graph.json ──────────────────────────────────
{
  echo '{'
  echo '  "type": "workflow-graph",'
  echo '  "description": "CI/CD workflows i git hooks",'
  echo '  "workflows": ['
  find "$ROOT/.github/workflows" -name '*.yml' 2>/dev/null | sort | while read -r wf; do
    b="$(basename "$wf")"
    echo "    {\"file\":\".github/workflows/$b\",\"calls_verify\":false}"
  done | join
  echo '  ],'
  echo '  "git_hooks": ['
  echo '    {"file":".git-hooks/pre-commit","type":"pre-commit","calls_verify":false},'
  echo '    {"file":".git-hooks/pre-push","type":"pre-push","calls_verify":false},'
  echo '    {"file":".git-hooks/validate-sot","type":"validate-sot","calls_verify":false}'
  echo '  ]'
  echo '}'
} > "$OUT/workflow-graph.json"

echo "Wygenerowano 9 plików JSON w $OUT"
