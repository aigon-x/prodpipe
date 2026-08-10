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
)

# ── Profile → moduły ─────────────────────────────────────────
# Każdy profil uruchamia listę modułów z domyślną klasą.
verify_profile_modules() {
  local profile="$1"
  case "$profile" in
    fast)
      echo "git security structure"
      ;;
    full)
      echo "git security structure architecture dependencies reproducibility deployment contracts migration recovery"
      ;;
    security)
      echo "git security"
      ;;
    architecture)
      echo "architecture contracts"
      ;;
    reproducibility)
      echo "reproducibility dependencies"
      ;;
    release)
      echo "git security structure architecture dependencies reproducibility deployment contracts migration recovery"
      ;;
    genesis)
      echo "git security structure architecture dependencies reproducibility deployment contracts migration recovery"
      ;;
    all)
      echo "git security structure architecture dependencies reproducibility deployment contracts migration recovery"
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
