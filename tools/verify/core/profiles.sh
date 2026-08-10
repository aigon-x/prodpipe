#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# profiles.sh — AIGON Production Platform — Repository Certification Engine
# Definicje profili (L0-L3) i mapowanie modułów na profile.
#
# Poziomy:
#   L0 FAST   — pre-commit, <5-10s, oczywiste błędy
#   L1 FULL   — pre-push, <1-3min, pełna certyfikacja lokalnego drzewa
#   L2 REMOTE — CI, niezależna weryfikacja
#   L3 RELEASE/GENESIS — pełna certyfikacja baseline/release
# ─────────────────────────────────────────────────────────────
# GENERATED FILE — DO NOT EDIT. Edytuj config/canonical/gates.yaml
# i uruchom tools/verify/core/gen-profiles.sh.
# ─────────────────────────────────────────────────────────────

# ── Moduły i ich klasy ───────────────────────────────────────
# Format: <module>:<profile>:<severity>
#   module   — nazwa modułu (git, security, structure, ...)
#   profile  — fast | full | security | architecture | reproducibility | release | genesis | all
#   severity — BLOCKING | WARNING | INFORMATIONAL

VERIFY_MODULES=(
  "git:fast:BLOCKING"
  "git:full:BLOCKING"
  "git:security:BLOCKING"
  "git:release:BLOCKING"
  "git:genesis:BLOCKING"
  "security:fast:BLOCKING"
  "security:full:BLOCKING"
  "security:security:BLOCKING"
  "security:release:BLOCKING"
  "security:genesis:BLOCKING"
  "structure:fast:BLOCKING"
  "structure:full:BLOCKING"
  "structure:release:BLOCKING"
  "structure:genesis:BLOCKING"
  "architecture:full:BLOCKING"
  "architecture:release:BLOCKING"
  "architecture:genesis:BLOCKING"
  "dependencies:full:WARNING"
  "dependencies:release:BLOCKING"
  "dependencies:genesis:BLOCKING"
  "reproducibility:full:WARNING"
  "reproducibility:release:BLOCKING"
  "reproducibility:genesis:BLOCKING"
  "deployment:full:WARNING"
  "deployment:release:BLOCKING"
  "deployment:genesis:BLOCKING"
  "contracts:full:WARNING"
  "contracts:release:BLOCKING"
  "contracts:genesis:BLOCKING"
  "migration:full:WARNING"
  "migration:release:BLOCKING"
  "migration:genesis:BLOCKING"
  "recovery:full:WARNING"
  "recovery:release:BLOCKING"
  "recovery:genesis:BLOCKING"
  "aesthetics:fast:BLOCKING"
  "aesthetics:full:BLOCKING"
  "aesthetics:release:BLOCKING"
  "aesthetics:genesis:BLOCKING"
  "semantics:full:BLOCKING"
  "semantics:architecture:BLOCKING"
  "semantics:release:BLOCKING"
  "semantics:genesis:BLOCKING"
  "security-drills:full:BLOCKING"
  "security-drills:security:BLOCKING"
  "security-drills:release:BLOCKING"
  "security-drills:genesis:BLOCKING"
  "taxonomy:full:BLOCKING"
  "taxonomy:architecture:BLOCKING"
  "taxonomy:release:BLOCKING"
  "taxonomy:genesis:BLOCKING"
  "i18n:full:BLOCKING"
  "i18n:release:BLOCKING"
  "i18n:genesis:BLOCKING"
)

# ── Profile → moduły ─────────────────────────────────────────
# Każdy profil uruchamia listę modułów z domyślną klasą.
verify_profile_modules() {
  local profile="$1"
  case "$profile" in
    fast)
      echo "git security structure aesthetics"
      ;;
    full)
      echo "git security structure architecture dependencies reproducibility deployment contracts migration recovery aesthetics semantics security-drills taxonomy i18n"
      ;;
    security)
      echo "git security security-drills"
      ;;
    architecture)
      echo "architecture contracts semantics taxonomy"
      ;;
    reproducibility)
      echo "reproducibility dependencies"
      ;;
    release)
      echo "git security structure architecture dependencies reproducibility deployment contracts migration recovery aesthetics semantics security-drills taxonomy i18n"
      ;;
    genesis)
      echo "git security structure architecture dependencies reproducibility deployment contracts migration recovery aesthetics semantics security-drills taxonomy i18n"
      ;;
    all)
      echo "git security structure architecture dependencies reproducibility deployment contracts migration recovery aesthetics semantics security-drills taxonomy i18n"
      ;;
    *)
      echo "git security structure"
      ;;
  esac
}

# ── Domyślna klasa dla modułu w profilu ──────────────────────
verify_module_severity() {
  local module="$1" profile="$2"
  for entry in "${VERIFY_MODULES[@]}"; do
    local m="${entry%%:*}"
    local rest="${entry#*:}"
    local p="${rest%%:*}"
    local s="${rest#*:}"
    if [ "$m" = "$module" ] && [ "$p" = "$profile" ]; then
      echo "$s"
      return
    fi
  done
  echo "WARNING"
}

# ── Mapowanie nazwy modułu → ścieżka skryptu ────────────────
# Każdy moduł zadeklarowany w VERIFY_MODULES ma odpowiadający skrypt
# w tools/verify/<kategoria>/<nazwa>.sh. To jest JEDYNE miejsce mapowania —
# profiles.sh deklaruje moduły, verify.sh je uruchamia, a SELF-001
# weryfikuje integralność (każdy zadeklarowany moduł MUSI istnieć).
# Rozjazd (FALSE GATE) jest tu eliminowany.
module_script() {
  local module="$1"
  case "$module" in
    git)                   echo "git/integrity.sh" ;;
    security)              echo "security/secrets.sh" ;;
    structure)             echo "structure/readme.sh" ;;
    architecture)          echo "architecture/architecture.sh" ;;
    dependencies)          echo "dependencies/dependencies.sh" ;;
    reproducibility)       echo "reproducibility/reproducibility.sh" ;;
    deployment)            echo "deployment/deployment.sh" ;;
    contracts)             echo "contracts/contracts.sh" ;;
    migration)             echo "migration/migration.sh" ;;
    recovery)              echo "recovery/recovery.sh" ;;
    aesthetics)            echo "aesthetics/aesthetics.sh" ;;
    semantics)             echo "architecture/semantics.sh" ;;
    security-drills)       echo "security/drills.sh" ;;
    taxonomy)              echo "architecture/taxonomy.sh" ;;
    i18n)                  echo "i18n/i18n.sh" ;;
    *)              echo "" ;;
  esac
}
