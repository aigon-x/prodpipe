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
  "P-079|HUMAN-SIMULATION|human/setup.sh|STANDARD|IMPLEMENTED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-080|HUMAN-SIMULATION|human/navigate.sh|STANDARD|IMPLEMENTED|P-079|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-081|HUMAN-SIMULATION|human/wait.sh|STANDARD|IMPLEMENTED|P-080|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-082|HUMAN-SIMULATION|human/screenshot.sh|STANDARD|IMPLEMENTED|P-081|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-083|HUMAN-SIMULATION|human/interact.sh|STANDARD|IMPLEMENTED|P-082|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-084|HUMAN-SIMULATION|human/assert.sh|STANDARD|IMPLEMENTED|P-083|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-085|HUMAN-SIMULATION|human/record.sh|STANDARD|IMPLEMENTED|P-084|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-086|HUMAN-SIMULATION|human/report.sh|STANDARD|IMPLEMENTED|P-085|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-087|HUMAN-SIMULATION|human/replay.sh|DEEP|IMPLEMENTED|P-086|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-088|HUMAN-SIMULATION|human/terminal.sh|DEEP|IMPLEMENTED|P-087|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-089|HUMAN-SIMULATION|human/vm.sh|DEEP|IMPLEMENTED|P-088|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-090|SIMULATION|simulation/scenario.sh|STANDARD|IMPLEMENTED||DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-091|SIMULATION|simulation/prepare.sh|STANDARD|IMPLEMENTED|P-090|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-092|SIMULATION|simulation/execute.sh|STANDARD|IMPLEMENTED|P-091|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-093|SIMULATION|simulation/observe.sh|STANDARD|IMPLEMENTED|P-092|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-094|SIMULATION|simulation/measure.sh|STANDARD|IMPLEMENTED|P-093|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-095|SIMULATION|simulation/evaluate.sh|STANDARD|IMPLEMENTED|P-094|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-096|SIMULATION|simulation/remediate.sh|STANDARD|IMPLEMENTED|P-095|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-097|SIMULATION|simulation/document.sh|STANDARD|IMPLEMENTED|P-096|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
  "P-098|SIMULATION|simulation/repeat.sh|DEEP|IMPLEMENTED|P-097|DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT"
)

# ── Metadane MON-* (Monitor Plane) ──────────────────────────
# Format: <id>|<schedule>|<schedule_spec>|<control>|<monitor>|<notify>|<timeout>|<retries>|<priority>
#   schedule      — cron | interval | event | conditional | manual | reminder | escalation
#   schedule_spec — specyfikacja (cron expr / sekundy / nazwa eventu / warunek)
#   control       — dozwolone akcje kontrolne (przecinkami)
#   monitor       — elementy monitorowania (przecinkami)
#   notify        — kanały powiadomień (przecinkami)
#   timeout       — limit czasu wykonania (sekundy)
#   retries       — maksymalna liczba ponowień
#   priority      — LOW | NORMAL | HIGH | CRITICAL

PIPELINE_MON=(
  "P-001|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-002|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-003|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-004|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-005|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-006|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-007|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-008|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-009|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-010|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-011|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-012|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-013|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-014|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-015|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-016|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-017|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-018|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-019|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-020|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-021|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-022|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-023|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-024|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-025|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-026|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-027|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-028|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-029|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-030|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-031|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-032|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-033|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-034|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-035|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-036|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-037|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-038|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-039|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-040|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-041|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-042|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-043|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-044|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-045|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-046|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-047|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-048|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-049|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-050|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-051|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-052|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-053|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-054|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-055|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-056|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-057|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-058|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-059|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-060|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-061|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-062|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-063|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-064|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-065|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-066|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-067|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-068|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-069|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-070|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-071|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-072|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-073|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-074|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-075|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-076|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-077|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-078|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-079|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-080|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-081|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-082|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-083|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-084|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-085|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-086|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-087|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-088|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-089|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-090|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-091|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-092|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-093|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-094|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-095|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-096|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-097|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
  "P-098|manual||pause,resume,cancel,retry,skip,restart|status,progress,logs,metrics,dashboard,timeline|dashboard|300|3|NORMAL"
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
      echo "P-001 P-002 P-003 P-004 P-005 P-006 P-007 P-009 P-010 P-011 P-013 P-017 P-018 P-022 P-026 P-028 P-029 P-030 P-052 P-053 P-054 P-055 P-061 P-062 P-063 P-065 P-079 P-080 P-081 P-082 P-083 P-084 P-085 P-086 P-090 P-091 P-092 P-093 P-094 P-095 P-096 P-097"
      ;;
    DEEP)
      echo "P-008 P-012 P-014 P-015 P-019 P-023 P-027 P-038 P-051 P-064 P-070 P-071 P-072 P-073 P-074 P-075 P-076 P-077 P-078 P-087 P-088 P-089 P-098"
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

# ── Metadane MON-* (Monitor Plane) ──────────────────────────
# pipeline_mon_field <id> <field> — zwraca wartość pola MON-* dla pipeline'a.
#   field: schedule | schedule_spec | control | monitor | notify | timeout | retries | priority
# Pole 1 = id, pole 2 = schedule, ..., pole 9 = priority.
pipeline_mon_field() {
  local id="$1"
  local field="$2"
  local idx
  case "$field" in
    schedule)      idx=2 ;;
    schedule_spec) idx=3 ;;
    control)       idx=4 ;;
    monitor)       idx=5 ;;
    notify)        idx=6 ;;
    timeout)       idx=7 ;;
    retries)       idx=8 ;;
    priority)      idx=9 ;;
    *) echo ""; return ;;
  esac
  for entry in "${PIPELINE_MON[@]}"; do
    local eid="${entry%%|*}"
    if [ "$eid" = "$id" ]; then
      local rest="${entry#*|}"
      local i
      # rest = field2|field3|...|field9. Stripping (idx-2) more fields
      # leaves field `idx` at the front.
      for ((i=2; i<idx; i++)); do
        rest="${rest#*|}"
      done
      echo "${rest%%|*}"
      return
    fi
  done
  echo ""
}

# ── Wygodne akcesory MON-* ─────────────────────────────────
pipeline_schedule()      { pipeline_mon_field "$1" schedule; }
pipeline_schedule_spec() { pipeline_mon_field "$1" schedule_spec; }
pipeline_control()       { pipeline_mon_field "$1" control; }
pipeline_monitor()       { pipeline_mon_field "$1" monitor; }
pipeline_notify()        { pipeline_mon_field "$1" notify; }
pipeline_timeout()       { pipeline_mon_field "$1" timeout; }
pipeline_retries()       { pipeline_mon_field "$1" retries; }
pipeline_priority()      { pipeline_mon_field "$1" priority; }
