#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# pipelines.sh — AIGON Production Platform — Pipeline Operating System
# Katalog pipeline'ów (P-001..P-051) i mapowanie klas na pipeline'y.
#
# Klasy wykonania:
#   FAST       — <10s, pre-commit, oczywiste błędy
#   STANDARD   — <1-3min, pre-push, pełna certyfikacja lokalna
#   DEEP       — minuty, CI, niezależna weryfikacja
#   RELEASE    — pełna certyfikacja baseline/release
#   CONTINUOUS — ciągłe monitorowanie / asynchroniczne
# ─────────────────────────────────────────────────────────────
# GENERATED FILE — DO NOT EDIT. Edytuj config/canonical/pipelines.yaml
# i uruchom tools/automation/core/gen-pipelines.sh.
# ─────────────────────────────────────────────────────────────

# ── Pipeline'y i ich metadane ───────────────────────────────
# Format: <id>|<family>|<script>|<class>|<status>|<depends>|<contract>
#   id       — P-<seq>
#   family   — PRODUCT | DESIGN | SECURITY | CODE | BUILD | DEPLOYMENT | RUNTIME | RECOVERY
#   script   — ścieżka względem tools/automation/
#   class    — FAST | STANDARD | DEEP | RELEASE | CONTINUOUS
#   status   — IMPLEMENTED | PROPOSED
#   depends  — pipeline'y, które muszą przejść PRZED tym (przecinkami)
#   contract — 8 faz Pipeline Contract (przecinkami)

PIPELINES=(
  "P-001|PRODUCT|product/discovery.sh|STANDARD|PROPOSED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-002|PRODUCT|product/requirements.sh|STANDARD|PROPOSED|P-001|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-003|PRODUCT|product/traceability.sh|STANDARD|IMPLEMENTED|P-002|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-004|PRODUCT|product/prioritization.sh|FAST|PROPOSED|P-002|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-005|PRODUCT|product/roadmap.sh|STANDARD|PROPOSED|P-004|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-006|PRODUCT|product/backlog.sh|STANDARD|PROPOSED|P-005|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-007|PRODUCT|product/acceptance.sh|STANDARD|PROPOSED|P-003|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-008|DESIGN|design/architecture.sh|DEEP|PROPOSED|P-002|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-009|DESIGN|design/design-doc.sh|STANDARD|PROPOSED|P-008|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-010|DESIGN|design/contracts.sh|STANDARD|PROPOSED|P-009|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-011|DESIGN|design/interface.sh|STANDARD|PROPOSED|P-010|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-012|DESIGN|design/data-model.sh|DEEP|PROPOSED|P-010|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-013|DESIGN|design/tech-debt.sh|STANDARD|PROPOSED|P-008|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-014|DESIGN|design/change-impact.sh|DEEP|IMPLEMENTED|P-003|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-015|SECURITY|security/threat-model.sh|DEEP|PROPOSED|P-008|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-016|SECURITY|security/secrets.sh|FAST|PROPOSED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-017|SECURITY|security/dependency-scan.sh|STANDARD|PROPOSED|P-016|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-018|SECURITY|security/static-analysis.sh|STANDARD|PROPOSED|P-017|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-019|SECURITY|security/penetration.sh|DEEP|PROPOSED|P-018|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-020|SECURITY|security/compliance.sh|RELEASE|PROPOSED|P-019|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-021|CODE|code/unit-tests.sh|FAST|PROPOSED|P-010|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-022|CODE|code/integration-tests.sh|STANDARD|PROPOSED|P-021|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-023|CODE|code/e2e-tests.sh|DEEP|PROPOSED|P-022|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-024|CODE|code/lint.sh|FAST|PROPOSED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-025|CODE|code/format.sh|FAST|PROPOSED|P-024|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-026|CODE|code/coverage.sh|STANDARD|PROPOSED|P-021|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-027|CODE|code/performance.sh|DEEP|PROPOSED|P-022|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-028|CODE|code/review.sh|STANDARD|PROPOSED|P-025|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-029|BUILD|build/build.sh|STANDARD|PROPOSED|P-028|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-030|BUILD|build/artifact.sh|STANDARD|PROPOSED|P-029|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-031|BUILD|build/sbom.sh|RELEASE|PROPOSED|P-030|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-032|BUILD|build/reproducibility.sh|RELEASE|PROPOSED|P-030|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-033|BUILD|build/release.sh|RELEASE|PROPOSED|P-031,P-032|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-034|DEPLOYMENT|deployment/deploy.sh|RELEASE|PROPOSED|P-033|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-035|DEPLOYMENT|deployment/rollback.sh|RELEASE|PROPOSED|P-034|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-036|DEPLOYMENT|deployment/canary.sh|RELEASE|PROPOSED|P-034|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-037|DEPLOYMENT|deployment/blue-green.sh|RELEASE|PROPOSED|P-034|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-038|DEPLOYMENT|deployment/infrastructure.sh|DEEP|PROPOSED|P-034|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-039|RUNTIME|runtime/pipeline-governance.sh|CONTINUOUS|PROPOSED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-040|RUNTIME|runtime/gap-discovery.sh|CONTINUOUS|IMPLEMENTED|P-039|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-041|RUNTIME|runtime/temporal-assurance.sh|CONTINUOUS|PROPOSED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-042|RUNTIME|runtime/knowledge-consistency.sh|CONTINUOUS|PROPOSED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-043|RUNTIME|runtime/self-certification.sh|CONTINUOUS|IMPLEMENTED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-044|RUNTIME|runtime/continuous-certification.sh|CONTINUOUS|PROPOSED|P-043|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-045|RUNTIME|runtime/change-risk.sh|CONTINUOUS|PROPOSED|P-014|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-046|RUNTIME|runtime/selective-verification.sh|CONTINUOUS|PROPOSED|P-045|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-047|RUNTIME|runtime/unknown-management.sh|CONTINUOUS|PROPOSED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-048|RUNTIME|runtime/source-of-truth.sh|CONTINUOUS|PROPOSED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-049|RUNTIME|runtime/generated-artifact.sh|CONTINUOUS|PROPOSED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-050|RUNTIME|runtime/documentation.sh|CONTINUOUS|PROPOSED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-051|RECOVERY|recovery/max-decomposition.sh|DEEP|IMPLEMENTED|P-003|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
)

# ── Klasa → pipeline'y ──────────────────────────────────────
# Każda klasa uruchamia listę pipeline'ów z domyślną klasą.
pipeline_class_modules() {
  local class="$1"
  case "$class" in
    FAST)
      echo "P-016 P-021 P-024 P-025"
      ;;
    STANDARD)
      echo "P-001 P-002 P-003 P-004 P-005 P-006 P-007 P-009 P-010 P-011 P-013 P-017 P-018 P-022 P-026 P-028 P-029 P-030"
      ;;
    DEEP)
      echo "P-008 P-012 P-014 P-015 P-019 P-023 P-027 P-038 P-051"
      ;;
    RELEASE)
      echo "P-020 P-031 P-032 P-033 P-034 P-035 P-036 P-037"
      ;;
    CONTINUOUS)
      echo "P-039 P-040 P-041 P-042 P-043 P-044 P-045 P-046 P-047 P-048 P-049 P-050"
      ;;
    *)
      echo ""
      ;;
  esac
}
# ── Mapowanie id pipeline'a → ścieżka skryptu ───────────────
# Każdy pipeline zadeklarowany w PIPELINES ma odpowiadający skrypt
# w tools/automation/<rodzina>/<nazwa>.sh. To jest JEDYNE miejsce mapowania —
# pipelines.sh deklaruje pipeline'y, automation.sh je uruchamia, a P-039
# (PIPELINE GOVERNANCE) weryfikuje integralność (każdy zadeklarowany pipeline
# MUSI istnieć). Rozjazd (FALSE GATE) jest tu eliminowany.
pipeline_script() {
  local id="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      local family="${rest%%|*}"
      rest="${rest#*|}"
      local script="${rest%%|*}"
      echo "$script"
      return
    fi
  done
  echo ""
}

# ── Klasa pipeline'a ────────────────────────────────────────
pipeline_class() {
  local id="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      echo "${rest%%|*}"
      return
    fi
  done
  echo ""
}

# ── Status pipeline'a (IMPLEMENTED | PROPOSED) ──────────────
pipeline_status() {
  local id="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      echo "${rest%%|*}"
      return
    fi
  done
  echo ""
}

# ── Rodzina pipeline'a ──────────────────────────────────────
pipeline_family() {
  local id="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      echo "${rest%%|*}"
      return
    fi
  done
  echo ""
}

# ── Zależności pipeline'a (przecinkami) ─────────────────────
pipeline_depends() {
  local id="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      echo "${rest%%|*}"
      return
    fi
  done
  echo ""
}

# ── Kontrakt pipeline'a (przecinkami) ───────────────────────
pipeline_contract() {
  local id="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      rest="${rest#*|}"
      echo "${rest%%|*}"
      return
    fi
  done
  echo ""
}

# ── Lista pipeline'ów w rodzinie ────────────────────────────
pipeline_family_list() {
  local family="$1"
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    local rest="${entry#*|}"
    local fam="${rest%%|*}"
    if [ "$fam" = "$family" ]; then
      printf '%s ' "$eid"
    fi
  done
  echo ""
}

# ── Lista pipeline'ów IMPLEMENTED ───────────────────────────
pipeline_implemented() {
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    local rest="${entry#*|}"
    rest="${rest#*|}"
    rest="${rest#*|}"
    rest="${rest#*|}"
    local st="${rest%%|*}"
    if [ "$st" = "IMPLEMENTED" ]; then
      printf '%s ' "$eid"
    fi
  done
  echo ""
}

# ── Lista pipeline'ów PROPOSED ──────────────────────────────
pipeline_proposed() {
  for entry in "${PIPELINES[@]}"; do
    local eid="${entry%%|*}"
    local rest="${entry#*|}"
    rest="${rest#*|}"
    rest="${rest#*|}"
    rest="${rest#*|}"
    local st="${rest%%|*}"
    if [ "$st" = "PROPOSED" ]; then
      printf '%s ' "$eid"
    fi
  done
  echo ""
}
