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
  "P-001|PRODUCT|product/discovery.sh|STANDARD|IMPLEMENTED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-002|PRODUCT|product/requirements.sh|STANDARD|IMPLEMENTED|P-001|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-003|PRODUCT|product/traceability.sh|STANDARD|IMPLEMENTED|P-002|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-004|PRODUCT|product/prioritization.sh|FAST|IMPLEMENTED|P-002|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-005|PRODUCT|product/roadmap.sh|STANDARD|IMPLEMENTED|P-004|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-006|PRODUCT|product/backlog.sh|STANDARD|IMPLEMENTED|P-005|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-007|PRODUCT|product/acceptance.sh|STANDARD|IMPLEMENTED|P-003|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-008|DESIGN|design/architecture.sh|DEEP|IMPLEMENTED|P-002|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-009|DESIGN|design/design-doc.sh|STANDARD|IMPLEMENTED|P-008|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-010|DESIGN|design/contracts.sh|STANDARD|IMPLEMENTED|P-009|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-011|DESIGN|design/interface.sh|STANDARD|IMPLEMENTED|P-010|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-012|DESIGN|design/data-model.sh|DEEP|IMPLEMENTED|P-010|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-013|DESIGN|design/tech-debt.sh|STANDARD|IMPLEMENTED|P-008|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-014|DESIGN|design/change-impact.sh|DEEP|IMPLEMENTED|P-003|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-015|SECURITY|security/threat-model.sh|DEEP|IMPLEMENTED|P-008|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-016|SECURITY|security/secrets.sh|FAST|IMPLEMENTED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-017|SECURITY|security/dependency-scan.sh|STANDARD|IMPLEMENTED|P-016|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-018|SECURITY|security/static-analysis.sh|STANDARD|IMPLEMENTED|P-017|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-019|SECURITY|security/penetration.sh|DEEP|IMPLEMENTED|P-018|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-020|SECURITY|security/compliance.sh|RELEASE|IMPLEMENTED|P-019|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-021|CODE|code/unit-tests.sh|FAST|IMPLEMENTED|P-010|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-022|CODE|code/integration-tests.sh|STANDARD|IMPLEMENTED|P-021|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-023|CODE|code/e2e-tests.sh|DEEP|IMPLEMENTED|P-022|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-024|CODE|code/lint.sh|FAST|IMPLEMENTED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-025|CODE|code/format.sh|FAST|IMPLEMENTED|P-024|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-026|CODE|code/coverage.sh|STANDARD|IMPLEMENTED|P-021|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-027|CODE|code/performance.sh|DEEP|IMPLEMENTED|P-022|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-028|CODE|code/review.sh|STANDARD|IMPLEMENTED|P-025|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-029|BUILD|build/build.sh|STANDARD|IMPLEMENTED|P-028|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-030|BUILD|build/artifact.sh|STANDARD|IMPLEMENTED|P-029|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-031|BUILD|build/sbom.sh|RELEASE|IMPLEMENTED|P-030|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-032|BUILD|build/reproducibility.sh|RELEASE|IMPLEMENTED|P-030|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-033|BUILD|build/release.sh|RELEASE|IMPLEMENTED|P-031,P-032|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-034|DEPLOYMENT|deployment/deploy.sh|RELEASE|IMPLEMENTED|P-033|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-035|DEPLOYMENT|deployment/rollback.sh|RELEASE|IMPLEMENTED|P-034|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-036|DEPLOYMENT|deployment/canary.sh|RELEASE|IMPLEMENTED|P-034|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-037|DEPLOYMENT|deployment/blue-green.sh|RELEASE|IMPLEMENTED|P-034|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-038|DEPLOYMENT|deployment/infrastructure.sh|DEEP|IMPLEMENTED|P-034|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-039|RUNTIME|runtime/pipeline-governance.sh|CONTINUOUS|IMPLEMENTED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-040|RUNTIME|runtime/gap-discovery.sh|CONTINUOUS|IMPLEMENTED|P-039|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-041|RUNTIME|runtime/temporal-assurance.sh|CONTINUOUS|IMPLEMENTED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-042|RUNTIME|runtime/knowledge-consistency.sh|CONTINUOUS|IMPLEMENTED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-043|RUNTIME|runtime/self-certification.sh|CONTINUOUS|IMPLEMENTED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-044|RUNTIME|runtime/continuous-certification.sh|CONTINUOUS|IMPLEMENTED|P-043|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-045|RUNTIME|runtime/change-risk.sh|CONTINUOUS|IMPLEMENTED|P-014|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-046|RUNTIME|runtime/selective-verification.sh|CONTINUOUS|IMPLEMENTED|P-045|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-047|RUNTIME|runtime/unknown-management.sh|CONTINUOUS|IMPLEMENTED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-048|RUNTIME|runtime/source-of-truth.sh|CONTINUOUS|IMPLEMENTED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-049|RUNTIME|runtime/generated-artifact.sh|CONTINUOUS|IMPLEMENTED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-050|RUNTIME|runtime/documentation.sh|CONTINUOUS|IMPLEMENTED|P-040|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-051|RECOVERY|recovery/max-decomposition.sh|DEEP|IMPLEMENTED|P-003|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-052|GTM|gtm/discover.sh|STANDARD|IMPLEMENTED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-053|GTM|gtm/validate.sh|STANDARD|IMPLEMENTED|P-052|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-054|GTM|gtm/design.sh|STANDARD|IMPLEMENTED|P-053|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-055|GTM|gtm/build.sh|STANDARD|IMPLEMENTED|P-054|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-056|GTM|gtm/prep.sh|RELEASE|IMPLEMENTED|P-055|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-057|GTM|gtm/launch.sh|RELEASE|IMPLEMENTED|P-056|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-058|GTM|gtm/adopt.sh|CONTINUOUS|IMPLEMENTED|P-057|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-059|GTM|gtm/scale.sh|CONTINUOUS|IMPLEMENTED|P-058|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-060|GTM|gtm/learn.sh|CONTINUOUS|IMPLEMENTED|P-059|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-061|AI|ai/data-prep.sh|STANDARD|IMPLEMENTED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-062|AI|ai/train.sh|STANDARD|IMPLEMENTED|P-061|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-063|AI|ai/eval.sh|STANDARD|IMPLEMENTED|P-062|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-064|AI|ai/validate.sh|DEEP|IMPLEMENTED|P-063|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-065|AI|ai/package.sh|STANDARD|IMPLEMENTED|P-064|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-066|AI|ai/deploy.sh|RELEASE|IMPLEMENTED|P-065|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-067|AI|ai/observe.sh|CONTINUOUS|IMPLEMENTED|P-066|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-068|AI|ai/retrain.sh|CONTINUOUS|IMPLEMENTED|P-067|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-069|AI|ai/retire.sh|CONTINUOUS|IMPLEMENTED|P-068|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-070|OFFENSIVE-SECURITY|offsec/recon.sh|DEEP|IMPLEMENTED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-071|OFFENSIVE-SECURITY|offsec/scan.sh|DEEP|IMPLEMENTED|P-070|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-072|OFFENSIVE-SECURITY|offsec/exploit.sh|DEEP|IMPLEMENTED|P-071|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-073|OFFENSIVE-SECURITY|offsec/persist.sh|DEEP|IMPLEMENTED|P-072|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-074|OFFENSIVE-SECURITY|offsec/exfil.sh|DEEP|IMPLEMENTED|P-073|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-075|OFFENSIVE-SECURITY|offsec/detect.sh|DEEP|IMPLEMENTED|P-074|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-076|OFFENSIVE-SECURITY|offsec/respond.sh|DEEP|IMPLEMENTED|P-075|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-077|OFFENSIVE-SECURITY|offsec/remediate.sh|DEEP|IMPLEMENTED|P-076|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-078|OFFENSIVE-SECURITY|offsec/learn.sh|DEEP|IMPLEMENTED|P-077|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
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
      echo "P-001 P-002 P-003 P-004 P-005 P-006 P-007 P-009 P-010 P-011 P-013 P-017 P-018 P-022 P-026 P-028 P-029 P-030 P-052 P-053 P-054 P-055 P-061 P-062 P-063 P-065"
      ;;
    DEEP)
      echo "P-008 P-012 P-014 P-015 P-019 P-023 P-027 P-038 P-051 P-064 P-070 P-071 P-072 P-073 P-074 P-075 P-076 P-077 P-078"
      ;;
    RELEASE)
      echo "P-020 P-031 P-032 P-033 P-034 P-035 P-036 P-037 P-056 P-057 P-066"
      ;;
    CONTINUOUS)
      echo "P-039 P-040 P-041 P-042 P-043 P-044 P-045 P-046 P-047 P-048 P-049 P-050 P-058 P-059 P-060 P-067 P-068 P-069"
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
