#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# registry.sh — GATE REGISTRY (World-Class Engineering Gate System v1.0)
# AIGON Production Platform — Repository Certification Engine
#
# Registry jest JEDYNYM źródłem prawdy o gate'ach.
# Każdy gate ma pełny wpis: gate_id, domain, name, description, owner,
# severity, profile, command, inputs, outputs, pass_condition, fail_condition,
# exit_code, pipeline_stage, blocking, evidence_type, baseline, threshold,
# dependencies, documentation, test, status.
#
# GATE-INTEGRITY meta-gate porównuje registry z implementacją (skrypty),
# wiring (enforcement), wykonaniem (evidence) — wykrywa false/shadow/orphan.
#
# Zasada: registry == implemented == wired == executed.
# ─────────────────────────────────────────────────────────────
set -u

# ── Ścieżka do katalogu gates ────────────────────────────────
GATES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Format wpisu gate w registry ─────────────────────────────
# Każdy wpis to linia z polami rozdzielonymi tabulatorem (\t).
# Kolejność pól (stała — GATE-INTEGRITY zależy od niej):
#   1  gate_id
#   2  domain
#   3  name
#   4  description
#   5  owner
#   6  severity
#   7  profile
#   8  command
#   9  inputs
#   10 outputs
#   11 pass_condition
#   12 fail_condition
#   13 exit_code
#   14 pipeline_stage
#   15 blocking
#   16 evidence_type
#   17 baseline
#   18 threshold
#   19 dependencies
#   20 documentation
#   21 test
#   22 status
#
# profile: LOCAL_FAST | PRE_PUSH | CI | RELEASE
# severity: critical | high | medium | low
# blocking: true | false
# evidence_type: exit_code | artifact | state | ci
# status: PROPOSED | IMPLEMENTED | WIRED | EXECUTED | ENFORCED | CERTIFIED | DEPRECATED | RETIRED

# ── Registry (tablica wpisów) ────────────────────────────────
# Wpisy są definiowane w sekcjach poniżej (GATE-001..GATE-020).
GATE_REGISTRY=(
  # ── GATE-INTEGRITY (meta-gate) ─────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-001' 'GATE-INTEGRITY' 'Registry==Implemented==Wired==Executed' \
    'Meta-gate: weryfikuje spojnosc calego systemu gateow (registry==implemented==wired==executed, brak false/shadow/orphan gate, brak unconnected check, brak missing evidence, brak broken exit code, brak bypass)' \
    'platform' 'critical' 'RELEASE' 'tools/verify/gates/gate-integrity.sh' \
    'registry.sh, enforcement.sh, evidence.sh, tools/verify/gates/domains/*.sh' \
    'artifacts/reports/gates/integrity.md' \
    'registry==implemented==wired==executed, brak P0' \
    'jakikolwiek rozjazd registry/implementacja/wiring/evidence' \
    '0' 'certify' 'true' 'exit_code' 'registry' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_gate_integrity.sh' 'IMPLEMENTED' )"
  # ── SOURCE-OF-TRUTH ────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-002' 'SOURCE-OF-TRUTH' 'SoT git==desired state' \
    'Weryfikuje że git (desired state) jest spójny z deklarowanym Source of Truth' \
    'platform' 'critical' 'PRE_PUSH' 'tools/verify/gates/domains/source-of-truth.sh' \
    'SOURCE-OF-TRUTH.md, git' \
    'artifacts/evidence/gates/GATE-002.evidence' \
    'SOURCE-OF-TRUTH.md istnieje i ma STATUS zdefiniowany' \
    'brak SOURCE-OF-TRUTH.md lub STATUS UNDEFINED' \
    '0' 'pre-push' 'true' 'exit_code' 'SOURCE-OF-TRUTH.md' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_source_of_truth.sh' 'IMPLEMENTED' )"
  # ── CANONICALITY ───────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-003' 'CANONICALITY' 'config/canonical jest jedynym źródłem prawdy' \
    'Weryfikuje że config/canonical jest jedynym źródłem prawdy konfiguracji, brak duplikacji w config/schemas' \
    'platform' 'high' 'PRE_PUSH' 'tools/verify/gates/domains/canonicality.sh' \
    'config/canonical/schema.md, config/schemas/schema.md' \
    'artifacts/evidence/gates/GATE-003.evidence' \
    'config/canonical/schema.md istnieje i jest spójny' \
    'brak config/canonical/schema.md lub rozjazd z config/schemas' \
    '0' 'pre-push' 'true' 'exit_code' 'config/canonical/schema.md' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_canonicality.sh' 'IMPLEMENTED' )"
  # ── CONFIGURATION ──────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-004' 'CONFIGURATION' 'Każdy element ma źródło konfiguracji' \
    'Weryfikuje że każdy element konfiguracji ma źródło, właściciela, kontrakt, walidację, konsumenta, drift detection' \
    'platform' 'high' 'PRE_PUSH' 'tools/verify/gates/domains/configuration.sh' \
    'config/' \
    'artifacts/evidence/gates/GATE-004.evidence' \
    'config/ ma strukturę canonical/schemas/templates/examples' \
    'brak struktury config/ lub brak kontraktu' \
    '0' 'pre-push' 'true' 'exit_code' 'config/' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_configuration.sh' 'IMPLEMENTED' )"
  # ── SECURITY ───────────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-005' 'SECURITY' 'Brak hardcoded sekretów' \
    'Weryfikuje brak sekretów w repo (secret-scan, brak .env, brak kluczy)' \
    'security' 'critical' 'LOCAL_FAST' 'tools/verify/gates/domains/security.sh' \
    'repo (git ls-files)' \
    'artifacts/evidence/gates/GATE-005.evidence' \
    'brak plików .env/.pem/.key/.p12/.pfx w repo' \
    'znaleziono sekret w repo' \
    '0' 'pre-commit' 'true' 'exit_code' '0 sekretów' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_security.sh' 'IMPLEMENTED' )"
  # ── STRUCTURE ──────────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-006' 'STRUCTURE' 'Struktura katalogów zgodna z kontraktem' \
    'Weryfikuje że struktura katalogów repo jest zgodna z deklarowanym kontraktem' \
    'platform' 'high' 'LOCAL_FAST' 'tools/verify/gates/domains/structure.sh' \
    'repo (katalogi top-level)' \
    'artifacts/evidence/gates/GATE-006.evidence' \
    'wymagane katalogi top-level istnieją' \
    'brak wymaganego katalogu top-level' \
    '0' 'pre-commit' 'true' 'exit_code' 'MAP.md' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_structure.sh' 'IMPLEMENTED' )"
  # ── ARCHITECTURE ───────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-007' 'ARCHITECTURE' 'Architektura zgodna z deklaracją' \
    'Weryfikuje że architektura repo jest zgodna z ARCHITECTURE.md' \
    'platform' 'high' 'PRE_PUSH' 'tools/verify/gates/domains/architecture.sh' \
    'ARCHITECTURE.md' \
    'artifacts/evidence/gates/GATE-007.evidence' \
    'ARCHITECTURE.md istnieje' \
    'brak ARCHITECTURE.md' \
    '0' 'pre-push' 'true' 'exit_code' 'ARCHITECTURE.md' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_architecture.sh' 'IMPLEMENTED' )"
  # ── DEPENDENCIES ───────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-008' 'DEPENDENCIES' 'Brak nieznanych zależności' \
    'Weryfikuje że zależności są zadeklarowane (Cargo.toml/package.json/requirements.txt)' \
    'platform' 'medium' 'PRE_PUSH' 'tools/verify/gates/domains/dependencies.sh' \
    'Cargo.toml, package.json, requirements.txt' \
    'artifacts/evidence/gates/GATE-008.evidence' \
    'zależności zadeklarowane w manifestach' \
    'brak manifestów zależności' \
    '0' 'pre-push' 'false' 'exit_code' 'manifesty' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_dependencies.sh' 'IMPLEMENTED' )"
  # ── REPRODUCIBILITY ────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-009' 'REPRODUCIBILITY' 'Reprodukowalność build/deploy' \
    'Weryfikuje że build/deploy jest reprodukowalny (deploy.sh, stack.yaml)' \
    'platform' 'medium' 'RELEASE' 'tools/verify/gates/domains/reproducibility.sh' \
    'deploy.sh, stack.yaml' \
    'artifacts/evidence/gates/GATE-009.evidence' \
    'deploy.sh i stack.yaml istnieją' \
    'brak deploy.sh lub stack.yaml' \
    '0' 'release' 'false' 'exit_code' 'deploy.sh' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_reproducibility.sh' 'IMPLEMENTED' )"
  # ── DEPLOYMENT ─────────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-010' 'DEPLOYMENT' 'Deploy zgodny z kontraktem' \
    'Weryfikuje że deploy jest zgodny z DEPLOYMENT.md' \
    'platform' 'medium' 'RELEASE' 'tools/verify/gates/domains/deployment.sh' \
    'DEPLOYMENT.md' \
    'artifacts/evidence/gates/GATE-010.evidence' \
    'DEPLOYMENT.md istnieje' \
    'brak DEPLOYMENT.md' \
    '0' 'release' 'false' 'exit_code' 'DEPLOYMENT.md' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_deployment.sh' 'IMPLEMENTED' )"
  # ── CONTRACTS ──────────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-011' 'CONTRACTS' 'Kontrakty README/API spełnione' \
    'Weryfikuje że README spełniają 12-sekcyjny kontrakt' \
    'platform' 'high' 'PRE_PUSH' 'tools/verify/gates/domains/contracts.sh' \
    'README.md (poza root)' \
    'artifacts/evidence/gates/GATE-011.evidence' \
    'wszystkie README mają 12 wymaganych sekcji' \
    'README bez wymaganych sekcji' \
    '0' 'pre-push' 'true' 'exit_code' '12 sekcji' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_contracts.sh' 'IMPLEMENTED' )"
  # ── MIGRATION ──────────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-012' 'MIGRATION' 'Migracje StateStore spójne' \
    'Weryfikuje że migracje StateStore są spójne i sekwencyjne' \
    'platform' 'high' 'PRE_PUSH' 'tools/verify/gates/domains/migration.sh' \
    'system/control-plane/state/migrations/*.sql' \
    'artifacts/evidence/gates/GATE-012.evidence' \
    'migracje są sekwencyjne (0001,0002,...) i schema_version zgodna' \
    'migracje niesekwencyjne lub schema_version niezgodna' \
    '0' 'pre-push' 'true' 'exit_code' 'migrations/' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_migration.sh' 'IMPLEMENTED' )"
  # ── RECOVERY ───────────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-013' 'RECOVERY' 'Backup/restore działa' \
    'Weryfikuje że backup/restore StateStore działa (test negatywny + realny test)' \
    'platform' 'high' 'RELEASE' 'tools/verify/gates/domains/recovery.sh' \
    'system/control-plane/state/' \
    'artifacts/evidence/gates/GATE-013.evidence' \
    'state.sh backup-restore-test i rollback-test przechodzą' \
    'backup/restore test FAIL' \
    '0' 'release' 'true' 'exit_code' 'state.sh' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_recovery.sh' 'IMPLEMENTED' )"
  # ── TESTING ────────────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-014' 'TESTING' 'Testy istnieją, nie są puste, nie są false green' \
    'Weryfikuje ze testy istnieja, nie sa puste, nie sa false green (test_state.sh, testy gateow)' \
    'platform' 'high' 'PRE_PUSH' 'tools/verify/gates/domains/testing.sh' \
    'system/control-plane/state/tests/, tools/verify/gates/tests/' \
    'artifacts/evidence/gates/GATE-014.evidence' \
    'testy istnieją i nie są puste' \
    'brak testów lub puste testy' \
    '0' 'pre-push' 'true' 'exit_code' 'testy' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_testing.sh' 'IMPLEMENTED' )"
  # ── PERFORMANCE ────────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-015' 'PERFORMANCE' 'Progi wydajności' \
    'Weryfikuje że LOCAL_FAST profile wykonuje się w limicie czasu' \
    'platform' 'low' 'LOCAL_FAST' 'tools/verify/gates/domains/performance.sh' \
    'tools/verify/gates/' \
    'artifacts/evidence/gates/GATE-015.evidence' \
    'LOCAL_FAST wykonuje się < 30s' \
    'LOCAL_FAST przekracza limit czasu' \
    '0' 'pre-commit' 'false' 'exit_code' '30s' '30' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_performance.sh' 'IMPLEMENTED' )"
  # ── DOCUMENTATION ──────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-016' 'DOCUMENTATION' 'Dokumentacja zgodna z kontraktem 12-sekcyjnym' \
    'Weryfikuje że docs/00-foundation spełnia kontrakt dokumentacyjny' \
    'platform' 'medium' 'PRE_PUSH' 'tools/verify/gates/domains/documentation.sh' \
    'docs/00-foundation/' \
    'artifacts/evidence/gates/GATE-016.evidence' \
    'docs/00-foundation/ ma wymagane pliki' \
    'brak wymaganych plików docs/00-foundation/' \
    '0' 'pre-push' 'false' 'exit_code' 'docs/00-foundation/' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_documentation.sh' 'IMPLEMENTED' )"
  # ── CI ─────────────────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-017' 'CI' 'Workflow CI wywołują verify.sh gates' \
    'Weryfikuje że co najmniej ci.yml i release.yml wywołują verify.sh gates' \
    'platform' 'high' 'CI' 'tools/verify/gates/domains/ci.sh' \
    '.github/workflows/ci.yml, .github/workflows/release.yml' \
    'artifacts/evidence/gates/GATE-017.evidence' \
    'ci.yml i release.yml wywołują verify.sh gates' \
    'CI nie wywołuje verify.sh gates' \
    '0' 'ci' 'true' 'exit_code' 'ci.yml, release.yml' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_ci.sh' 'IMPLEMENTED' )"
  # ── GIT-HOOKS ──────────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-018' 'GIT-HOOKS' 'pre-commit/pre-push/validate-sot działają' \
    'Weryfikuje że git hooks istnieją, są wykonywalne i wywołują verify.sh gates' \
    'platform' 'high' 'LOCAL_FAST' 'tools/verify/gates/domains/git-hooks.sh' \
    '.git-hooks/' \
    'artifacts/evidence/gates/GATE-018.evidence' \
    'pre-commit i pre-push istnieją, są wykonywalne, wywołują verify.sh gates' \
    'brak hooka lub hook nie wywołuje verify.sh gates' \
    '0' 'pre-commit' 'true' 'exit_code' '.git-hooks/' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_git_hooks.sh' 'IMPLEMENTED' )"
  # ── STATE ──────────────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-019' 'STATE' 'StateStore spójny, schema_version zgodna' \
    'Weryfikuje że StateStore jest spójny i schema_version zgodna z lib.sh' \
    'platform' 'high' 'PRE_PUSH' 'tools/verify/gates/domains/state.sh' \
    'system/control-plane/state/' \
    'artifacts/evidence/gates/GATE-019.evidence' \
    'state.sh verify przechodzi, schema_version zgodna' \
    'state.sh verify FAIL lub schema_version niezgodna' \
    '0' 'pre-push' 'true' 'exit_code' 'state.sh' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_state_gate.sh' 'IMPLEMENTED' )"
  # ── EVIDENCE ───────────────────────────────────────────────
  "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    'GATE-020' 'EVIDENCE' 'Każdy gate ma evidence' \
    'Weryfikuje że każdy gate ma maszynowo weryfikowalny dowód wykonania w artifacts/evidence/gates/' \
    'platform' 'high' 'RELEASE' 'tools/verify/gates/domains/evidence.sh' \
    'artifacts/evidence/gates/' \
    'artifacts/evidence/gates/GATE-020.evidence' \
    'każdy gate ma plik evidence z exit code i timestamp' \
    'gate bez evidence' \
    '0' 'release' 'true' 'exit_code' 'artifacts/evidence/gates/' '0' 'GATE-INTEGRITY' 'docs/generated/gates/README.md' 'tools/verify/gates/tests/test_evidence.sh' 'IMPLEMENTED' )"
)

# ── Funkcje zapytań registry ─────────────────────────────────
# Zwraca liczbę gate'ów w registry.
registry_count() {
  echo "${#GATE_REGISTRY[@]}"
}

# ── Zwraca listę gate_id (pierwsze pole każdego wpisu) ───────
registry_gate_ids() {
  local entry
  for entry in "${GATE_REGISTRY[@]}"; do
    printf '%s\n' "$(printf '%s' "$entry" | cut -f1)"
  done
}

# ── Zwraca listę domen (drugie pole, unikalne) ───────────────
registry_domains() {
  local entry domain
  for entry in "${GATE_REGISTRY[@]}"; do
    domain="$(printf '%s' "$entry" | cut -f2)"
    printf '%s\n' "$domain"
  done | sort -u
}

# ── Zwraca pełny wpis gate po gate_id ────────────────────────
# Użycie: registry_get <gate_id>  → wypisuje wpis (tab-separated)
registry_get() {
  local gate_id="$1" entry
  for entry in "${GATE_REGISTRY[@]}"; do
    if [ "$(printf '%s' "$entry" | cut -f1)" = "$gate_id" ]; then
      printf '%s\n' "$entry"
      return 0
    fi
  done
  return 1
}

# ── Zwraca pole gate po gate_id ──────────────────────────────
# Użycie: registry_field <gate_id> <field_number>
registry_field() {
  local gate_id="$1" field="$2" entry
  entry="$(registry_get "$gate_id")" || return 1
  printf '%s\n' "$(printf '%s' "$entry" | cut -f"$field")"
}

# ── Zwraca listę gate_id dla danego profilu ──────────────────
# Użycie: registry_gates_for_profile <profile>
# RELEASE jest nadzbiorem — gate'y RELEASE działają we wszystkich profilach.
registry_gates_for_profile() {
  local profile="$1" entry gate_profile gate_id
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_profile="$(printf '%s' "$entry" | cut -f7)"
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    if [ "$profile" = "RELEASE" ]; then
      printf '%s\n' "$gate_id"
    elif [ "$gate_profile" = "$profile" ] || [ "$gate_profile" = "RELEASE" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id dla danej domeny ────────────────────
registry_gates_for_domain() {
  local domain="$1" entry gate_domain gate_id
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_domain="$(printf '%s' "$entry" | cut -f2)"
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    if [ "$gate_domain" = "$domain" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które są blocking=true ──────────────
registry_blocking_gates() {
  local entry gate_id blocking
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    blocking="$(printf '%s' "$entry" | cut -f15)"
    if [ "$blocking" = "true" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają status IMPLEMENTED ───────
registry_implemented_gates() {
  local entry gate_id status
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    status="$(printf '%s' "$entry" | cut -f22)"
    if [ "$status" = "IMPLEMENTED" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają status != IMPLEMENTED ────
registry_non_implemented_gates() {
  local entry gate_id status
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    status="$(printf '%s' "$entry" | cut -f22)"
    if [ "$status" != "IMPLEMENTED" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają test negatywny zdefiniowany ──
registry_gates_with_test() {
  local entry gate_id test
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    test="$(printf '%s' "$entry" | cut -f21)"
    if [ -n "$test" ] && [ "$test" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają testu negatywnego ────
registry_gates_without_test() {
  local entry gate_id test
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    test="$(printf '%s' "$entry" | cut -f21)"
    if [ -z "$test" ] || [ "$test" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają command zdefiniowany ─────
registry_gates_with_command() {
  local entry gate_id command
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    command="$(printf '%s' "$entry" | cut -f8)"
    if [ -n "$command" ] && [ "$command" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają command ──────────────
registry_gates_without_command() {
  local entry gate_id command
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    command="$(printf '%s' "$entry" | cut -f8)"
    if [ -z "$command" ] || [ "$command" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają evidence_type zdefiniowany ──
registry_gates_with_evidence_type() {
  local entry gate_id et
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    et="$(printf '%s' "$entry" | cut -f16)"
    if [ -n "$et" ] && [ "$et" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają evidence_type ────────
registry_gates_without_evidence_type() {
  local entry gate_id et
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    et="$(printf '%s' "$entry" | cut -f16)"
    if [ -z "$et" ] || [ "$et" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają exit_code zdefiniowany ───
registry_gates_with_exit_code() {
  local entry gate_id ec
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    ec="$(printf '%s' "$entry" | cut -f13)"
    if [ -n "$ec" ] && [ "$ec" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają exit_code ────────────
registry_gates_without_exit_code() {
  local entry gate_id ec
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    ec="$(printf '%s' "$entry" | cut -f13)"
    if [ -z "$ec" ] || [ "$ec" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają blocking zdefiniowany ────
registry_gates_with_blocking() {
  local entry gate_id blocking
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    blocking="$(printf '%s' "$entry" | cut -f15)"
    if [ -n "$blocking" ] && [ "$blocking" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają blocking ─────────────
registry_gates_without_blocking() {
  local entry gate_id blocking
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    blocking="$(printf '%s' "$entry" | cut -f15)"
    if [ -z "$blocking" ] || [ "$blocking" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają severity zdefiniowany ────
registry_gates_with_severity() {
  local entry gate_id severity
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    severity="$(printf '%s' "$entry" | cut -f6)"
    if [ -n "$severity" ] && [ "$severity" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają severity ─────────────
registry_gates_without_severity() {
  local entry gate_id severity
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    severity="$(printf '%s' "$entry" | cut -f6)"
    if [ -z "$severity" ] || [ "$severity" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają profile zdefiniowany ─────
registry_gates_with_profile() {
  local entry gate_id profile
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    profile="$(printf '%s' "$entry" | cut -f7)"
    if [ -n "$profile" ] && [ "$profile" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają profile ──────────────
registry_gates_without_profile() {
  local entry gate_id profile
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    profile="$(printf '%s' "$entry" | cut -f7)"
    if [ -z "$profile" ] || [ "$profile" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają dependencies zdefiniowane ──
registry_gates_with_dependencies() {
  local entry gate_id deps
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    deps="$(printf '%s' "$entry" | cut -f19)"
    if [ -n "$deps" ] && [ "$deps" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają dependencies ─────────
registry_gates_without_dependencies() {
  local entry gate_id deps
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    deps="$(printf '%s' "$entry" | cut -f19)"
    if [ -z "$deps" ] || [ "$deps" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają documentation zdefiniowaną ──
registry_gates_with_documentation() {
  local entry gate_id doc
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    doc="$(printf '%s' "$entry" | cut -f20)"
    if [ -n "$doc" ] && [ "$doc" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają documentation ────────
registry_gates_without_documentation() {
  local entry gate_id doc
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    doc="$(printf '%s' "$entry" | cut -f20)"
    if [ -z "$doc" ] || [ "$doc" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają pass_condition zdefiniowany ──
registry_gates_with_pass_condition() {
  local entry gate_id pc
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    pc="$(printf '%s' "$entry" | cut -f11)"
    if [ -n "$pc" ] && [ "$pc" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają pass_condition ───────
registry_gates_without_pass_condition() {
  local entry gate_id pc
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    pc="$(printf '%s' "$entry" | cut -f11)"
    if [ -z "$pc" ] || [ "$pc" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają fail_condition zdefiniowany ──
registry_gates_with_fail_condition() {
  local entry gate_id fc
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    fc="$(printf '%s' "$entry" | cut -f12)"
    if [ -n "$fc" ] && [ "$fc" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają fail_condition ───────
registry_gates_without_fail_condition() {
  local entry gate_id fc
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    fc="$(printf '%s' "$entry" | cut -f12)"
    if [ -z "$fc" ] || [ "$fc" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają pipeline_stage zdefiniowany ──
registry_gates_with_pipeline_stage() {
  local entry gate_id ps
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    ps="$(printf '%s' "$entry" | cut -f14)"
    if [ -n "$ps" ] && [ "$ps" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają pipeline_stage ───────
registry_gates_without_pipeline_stage() {
  local entry gate_id ps
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    ps="$(printf '%s' "$entry" | cut -f14)"
    if [ -z "$ps" ] || [ "$ps" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają baseline zdefiniowany ────
registry_gates_with_baseline() {
  local entry gate_id bl
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    bl="$(printf '%s' "$entry" | cut -f17)"
    if [ -n "$bl" ] && [ "$bl" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają baseline ─────────────
registry_gates_without_baseline() {
  local entry gate_id bl
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    bl="$(printf '%s' "$entry" | cut -f17)"
    if [ -z "$bl" ] || [ "$bl" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają threshold zdefiniowany ───
registry_gates_with_threshold() {
  local entry gate_id th
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    th="$(printf '%s' "$entry" | cut -f18)"
    if [ -n "$th" ] && [ "$th" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają threshold ────────────
registry_gates_without_threshold() {
  local entry gate_id th
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    th="$(printf '%s' "$entry" | cut -f18)"
    if [ -z "$th" ] || [ "$th" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają inputs zdefiniowane ──────
registry_gates_with_inputs() {
  local entry gate_id inputs
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    inputs="$(printf '%s' "$entry" | cut -f9)"
    if [ -n "$inputs" ] && [ "$inputs" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają inputs ───────────────
registry_gates_without_inputs() {
  local entry gate_id inputs
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    inputs="$(printf '%s' "$entry" | cut -f9)"
    if [ -z "$inputs" ] || [ "$inputs" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają outputs zdefiniowane ─────
registry_gates_with_outputs() {
  local entry gate_id outputs
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    outputs="$(printf '%s' "$entry" | cut -f10)"
    if [ -n "$outputs" ] && [ "$outputs" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają outputs ──────────────
registry_gates_without_outputs() {
  local entry gate_id outputs
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    outputs="$(printf '%s' "$entry" | cut -f10)"
    if [ -z "$outputs" ] || [ "$outputs" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają name zdefiniowany ────────
registry_gates_with_name() {
  local entry gate_id name
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    name="$(printf '%s' "$entry" | cut -f3)"
    if [ -n "$name" ] && [ "$name" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają name ─────────────────
registry_gates_without_name() {
  local entry gate_id name
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    name="$(printf '%s' "$entry" | cut -f3)"
    if [ -z "$name" ] || [ "$name" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają description zdefiniowany ──
registry_gates_with_description() {
  local entry gate_id desc
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    desc="$(printf '%s' "$entry" | cut -f4)"
    if [ -n "$desc" ] && [ "$desc" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają description ──────────
registry_gates_without_description() {
  local entry gate_id desc
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    desc="$(printf '%s' "$entry" | cut -f4)"
    if [ -z "$desc" ] || [ "$desc" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które mają owner zdefiniowany ───────
registry_gates_with_owner() {
  local entry gate_id owner
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    owner="$(printf '%s' "$entry" | cut -f5)"
    if [ -n "$owner" ] && [ "$owner" != "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}

# ── Zwraca listę gate_id które NIE mają owner ────────────────
registry_gates_without_owner() {
  local entry gate_id owner
  for entry in "${GATE_REGISTRY[@]}"; do
    gate_id="$(printf '%s' "$entry" | cut -f1)"
    owner="$(printf '%s' "$entry" | cut -f5)"
    if [ -z "$owner" ] || [ "$owner" = "-" ]; then
      printf '%s\n' "$gate_id"
    fi
  done
}
