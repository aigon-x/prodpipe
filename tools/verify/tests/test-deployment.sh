#!/usr/bin/env bash
# ============================================================================
# test-deployment.sh — DEPLOYMENT module tests (deployment.sh)
# ============================================================================
# Weryfikuje moduł tools/verify/deployment/deployment.sh:
#   T1: pełny deployment control plane → PASS (rc=0)
#   T2: fail-closed — brak deploy + brak kontraktu no-deployment
#       → D-001 FAIL (NO_DEPLOYMENT ≠ PASS, rc != 0)
#   T3: brak deploy + kontrakt no-deployment (deployment.yaml)
#       → D-001 NOT_APPLICABLE (info, rc=0)
#   T4: fail-closed — deploy.sh tylko (SCRIPT_ONLY, brak lifecycle)
#       → D-002 FAIL (SCRIPT EXISTS ≠ CONTROL PLANE, rc != 0)
#   T5: fail-closed — hardcoded env / :latest / secret w deploy
#       → D-005 FAIL (INVALID, rc != 0)
#   T6: fail-closed — manual steps > max_manual_steps
#       → D-004 FAIL (INVALID, rc != 0)
#   T7: fail-closed — brak weryfikacji artefaktu (digest/hash/version)
#       → D-007 FAIL (ARTIFACT EXISTS ≠ ARTIFACT VERIFIED, rc != 0)
#   T8: fail-closed — brak authorization/policy
#       → D-008 FAIL (rc != 0)
#   T9: fail-closed — deployment succeeds but verification fails
#       → D-006 FAIL (DEPLOYMENT SUCCESS ≠ DEPLOYMENT VERIFIED, rc != 0)
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# verify_root = git rev-parse), tworzą deploy.sh i registry.yaml, więc nie
# dotykają prawdziwego repo ani równoległej pracy innych subagentów.
# Ustawiamy VERIFY_STATE_DB na nieistniejącą bazę, żeby evidence_record
# nie psuł wyniku.
#
# Użycie: ./test-deployment.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
DEPLOY_SH="$VERIFY_DIR/deployment/deployment.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== DEPLOYMENT (WDROŻENIE) TESTS ==="

# ── Helper: buduje izolowane repo git z deploy.sh i registry.yaml ──────────
# Argumenty: <katalog_docelowy> [--no-deploy] [--no-deploy-contract]
#            [--script-only] [--hardcoded] [--manual-steps <N>]
#            [--no-artifact] [--no-auth] [--no-verify] [--max-manual-steps <N>]
# Tworzy git repo, tworzy config/canonical/registry.yaml z max_manual_steps,
# opcjonalnie deploy.sh (pełny control plane lub warianty), opcjonalnie
# deployment.yaml (kontrakt no-deployment). Zwraca ścieżkę.
make_isolated_repo() {
  local dir="$1"; shift
  local no_deploy=0
  local no_deploy_contract=0
  local script_only=0
  local hardcoded=0
  local manual_steps=0
  local no_artifact=0
  local no_auth=0
  local no_verify=0
  local max_manual_steps=3
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-deploy) no_deploy=1 ;;
      --no-deploy-contract) no_deploy_contract=1 ;;
      --script-only) script_only=1 ;;
      --hardcoded) hardcoded=1 ;;
      --manual-steps) manual_steps="$2"; shift ;;
      --no-artifact) no_artifact=1 ;;
      --no-auth) no_auth=1 ;;
      --no-verify) no_verify=1 ;;
      --max-manual-steps) max_manual_steps="$2"; shift ;;
    esac
    shift
  done
  mkdir -p "$dir"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "DEPLOY Test" )
  echo "# test" > "$dir/README.md"

  # registry.yaml — canonical config contract (max_manual_steps).
  mkdir -p "$dir/config/canonical"
  cat > "$dir/config/canonical/registry.yaml" <<EOF
gates:
  deployment.integrity.max_manual_steps:
    default: $max_manual_steps
    floor: 1
    ratchet: true
    reload: hot
    owner: platform
    tier: stable
    doc: "Maksymalna liczba ręcznych kroków w pipeline wdrożeniowym."
EOF

  # Deploy script.
  if [ "$no_deploy" -eq 0 ]; then
    if [ "$script_only" -eq 1 ]; then
      # SCRIPT_ONLY — deploy.sh to tylko "docker compose up", brak lifecycle.
      cat > "$dir/deploy.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# deploy — wdrożenie
docker compose up -d
echo "deployed"
EOF
    else
      # Pełny control plane (domyślnie) — lifecycle + artifact + auth + verify.
      # Warianty (--hardcoded / --no-artifact / --no-auth / --no-verify)
      # usuwają odpowiednie elementy, żeby wyzwolić FAIL.
      cat > "$dir/deploy.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
# deploy — pełny control plane
# health check
health() { curl -f http://localhost:8080/health; }
# readiness probe
readiness() { curl -f http://localhost:8080/ready; }
# rollback
rollback() { docker compose down && docker compose up -d --force-recreate; }
# verify — weryfikacja wersji (expected == actual running)
verify() {
  local expected_version="\$1"
  local actual_version
  actual_version="\$(curl -s http://localhost:8080/version)"
  [ "\$expected_version" == "\$actual_version" ] || exit 1
}
# artifact — immutable image digest
IMAGE_DIGEST="sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
# authorization / policy
approval() { echo "deployment requires approval"; }
policy() { echo "policy: only platform-lead can deploy"; }
# manual steps (0 domyślnie)
echo "deploying"
EOF
      # Warianty modyfikujące deploy.sh.
      if [ "$hardcoded" -eq 1 ]; then
        # Dodaj :latest (hardcoded env / nieprawidłowy artifact).
        cat >> "$dir/deploy.sh" <<'EOF'
IMAGE="myapp:latest"
EOF
      fi
      if [ "$no_artifact" -eq 1 ]; then
        # Usuń artifact digest + komentarz (brak weryfikacji artefaktu).
        sed -i '/IMAGE_DIGEST/d; /# artifact/d' "$dir/deploy.sh"
      fi
      if [ "$no_auth" -eq 1 ]; then
        # Usuń authorization/policy + komentarz.
        sed -i '/approval()/d; /policy()/d; /# authorization/d' "$dir/deploy.sh"
      fi
      if [ "$no_verify" -eq 1 ]; then
        # Usuń weryfikację wersji (deployment succeeds but verification fails).
        sed -i '/verify()/,/^}/d' "$dir/deploy.sh"
      fi
      # Manual steps (dodaj N kroków read).
      if [ "$manual_steps" -gt 0 ]; then
        local i
        for i in $(seq 1 "$manual_steps"); do
          echo "read -r _step$i" >> "$dir/deploy.sh"
        done
      fi
    fi
    chmod +x "$dir/deploy.sh"
  fi

  # Kontrakt no-deployment (deployment.yaml).
  if [ "$no_deploy_contract" -eq 1 ]; then
    cat > "$dir/config/canonical/deployment.yaml" <<'EOF'
# deployment.yaml — kontrakt wdrożeniowy.
# Repo jest czysto dokumentacyjne — deployment nie ma zastosowania.
no-deploy: true
documentation-only: true
EOF
  fi

  ( cd "$dir" && git add -A 2>/dev/null )
  echo "$dir"
}

# ── T1: pełny deployment control plane → PASS (rc=0) ───────────────────────
echo ""
echo "--- T1: pełny deployment control plane → PASS (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR" "$T5_DIR" "$T6_DIR" "$T7_DIR" "$T8_DIR" "$T9_DIR"' EXIT
make_isolated_repo "$T1_DIR" --max-manual-steps 3 >/dev/null

T1_OUT="$(cd "$T1_DIR" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$DEPLOY_SH" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] D-001" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] D-002" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] D-006" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] D-007" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] D-008"; then
  t_pass "pełny deployment control plane → PASS (rc=$T1_RC, D-001/002/006/007/008 PASS)"
else
  t_fail "pełny deployment control plane NIE dał PASS (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak deploy + brak kontraktu → D-001 FAIL ────────────
echo ""
echo "--- T2: fail-closed — brak deploy + brak kontraktu no-deployment → D-001 FAIL ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" --no-deploy >/dev/null

T2_OUT="$(cd "$T2_DIR" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$DEPLOY_SH" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] D-001"; then
  t_pass "brak deploy + brak kontraktu → D-001 FAIL (NO_DEPLOYMENT ≠ PASS, rc=$T2_RC)"
else
  t_fail "brak deploy + brak kontraktu NIE dał D-001 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -30
fi

# ── T3: brak deploy + kontrakt no-deployment → NOT_APPLICABLE ──────────────
echo ""
echo "--- T3: brak deploy + kontrakt no-deployment → D-001 NOT_APPLICABLE ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" --no-deploy --no-deploy-contract >/dev/null

T3_OUT="$(cd "$T3_DIR" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$DEPLOY_SH" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -eq 0 ] \
   && printf '%s' "$T3_OUT" | grep -q "NOT_APPLICABLE" \
   && printf '%s' "$T3_OUT" | grep -q "\[INFO\] D-001"; then
  t_pass "brak deploy + kontrakt no-deployment → D-001 NOT_APPLICABLE (rc=$T3_RC)"
else
  t_fail "brak deploy + kontrakt no-deployment NIE dał NOT_APPLICABLE (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -30
fi

# ── T4: fail-closed — deploy.sh tylko (SCRIPT_ONLY) → D-002 FAIL ───────────
echo ""
echo "--- T4: fail-closed — deploy.sh tylko (SCRIPT_ONLY, brak lifecycle) → D-002 FAIL ---"
T4_DIR="$(mktemp -d)"
make_isolated_repo "$T4_DIR" --script-only >/dev/null

T4_OUT="$(cd "$T4_DIR" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$DEPLOY_SH" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] D-002"; then
  t_pass "deploy.sh tylko → D-002 FAIL (SCRIPT EXISTS ≠ CONTROL PLANE, rc=$T4_RC)"
else
  t_fail "deploy.sh tylko NIE dał D-002 FAIL (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -30
fi

# ── T5: fail-closed — hardcoded env / :latest / secret → D-005 FAIL ────────
echo ""
echo "--- T5: fail-closed — hardcoded env / :latest / secret → D-005 FAIL ---"
T5_DIR="$(mktemp -d)"
make_isolated_repo "$T5_DIR" --hardcoded >/dev/null

T5_OUT="$(cd "$T5_DIR" && VERIFY_STATE_DB="$T5_DIR/nonexistent.db" bash "$DEPLOY_SH" 2>&1)"
T5_RC=$?
if [ "$T5_RC" -ne 0 ] && printf '%s' "$T5_OUT" | grep -q "\[FAIL\] D-005"; then
  t_pass "hardcoded env / :latest / secret → D-005 FAIL (INVALID, rc=$T5_RC)"
else
  t_fail "hardcoded env / :latest / secret NIE dał D-005 FAIL (rc=$T5_RC)"
  printf '%s\n' "$T5_OUT" | tail -30
fi

# ── T6: fail-closed — manual steps > max_manual_steps → D-004 FAIL ─────────
echo ""
echo "--- T6: fail-closed — manual steps > max_manual_steps → D-004 FAIL ---"
T6_DIR="$(mktemp -d)"
make_isolated_repo "$T6_DIR" --max-manual-steps 0 --manual-steps 2 >/dev/null

T6_OUT="$(cd "$T6_DIR" && VERIFY_STATE_DB="$T6_DIR/nonexistent.db" bash "$DEPLOY_SH" 2>&1)"
T6_RC=$?
if [ "$T6_RC" -ne 0 ] && printf '%s' "$T6_OUT" | grep -q "\[FAIL\] D-004"; then
  t_pass "manual steps > max_manual_steps → D-004 FAIL (INVALID, rc=$T6_RC)"
else
  t_fail "manual steps > max_manual_steps NIE dał D-004 FAIL (rc=$T6_RC)"
  printf '%s\n' "$T6_OUT" | tail -30
fi

# ── T7: fail-closed — brak weryfikacji artefaktu → D-007 FAIL ──────────────
echo ""
echo "--- T7: fail-closed — brak weryfikacji artefaktu (digest/hash/version) → D-007 FAIL ---"
T7_DIR="$(mktemp -d)"
make_isolated_repo "$T7_DIR" --no-artifact >/dev/null

T7_OUT="$(cd "$T7_DIR" && VERIFY_STATE_DB="$T7_DIR/nonexistent.db" bash "$DEPLOY_SH" 2>&1)"
T7_RC=$?
if [ "$T7_RC" -ne 0 ] && printf '%s' "$T7_OUT" | grep -q "\[FAIL\] D-007"; then
  t_pass "brak weryfikacji artefaktu → D-007 FAIL (ARTIFACT EXISTS ≠ ARTIFACT VERIFIED, rc=$T7_RC)"
else
  t_fail "brak weryfikacji artefaktu NIE dał D-007 FAIL (rc=$T7_RC)"
  printf '%s\n' "$T7_OUT" | tail -30
fi

# ── T8: fail-closed — brak authorization/policy → D-008 FAIL ───────────────
echo ""
echo "--- T8: fail-closed — brak authorization/policy → D-008 FAIL ---"
T8_DIR="$(mktemp -d)"
make_isolated_repo "$T8_DIR" --no-auth >/dev/null

T8_OUT="$(cd "$T8_DIR" && VERIFY_STATE_DB="$T8_DIR/nonexistent.db" bash "$DEPLOY_SH" 2>&1)"
T8_RC=$?
if [ "$T8_RC" -ne 0 ] && printf '%s' "$T8_OUT" | grep -q "\[FAIL\] D-008"; then
  t_pass "brak authorization/policy → D-008 FAIL (rc=$T8_RC)"
else
  t_fail "brak authorization/policy NIE dał D-008 FAIL (rc=$T8_RC)"
  printf '%s\n' "$T8_OUT" | tail -30
fi

# ── T9: fail-closed — deployment succeeds but verification fails → D-006 FAIL ──
echo ""
echo "--- T9: fail-closed — deployment succeeds but verification fails → D-006 FAIL ---"
T9_DIR="$(mktemp -d)"
make_isolated_repo "$T9_DIR" --no-verify >/dev/null

T9_OUT="$(cd "$T9_DIR" && VERIFY_STATE_DB="$T9_DIR/nonexistent.db" bash "$DEPLOY_SH" 2>&1)"
T9_RC=$?
if [ "$T9_RC" -ne 0 ] && printf '%s' "$T9_OUT" | grep -q "\[FAIL\] D-006"; then
  t_pass "deployment succeeds but verification fails → D-006 FAIL (DEPLOYMENT SUCCESS ≠ DEPLOYMENT VERIFIED, rc=$T9_RC)"
else
  t_fail "deployment succeeds but verification fails NIE dał D-006 FAIL (rc=$T9_RC)"
  printf '%s\n' "$T9_OUT" | tail -30
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== DEPLOYMENT (WDROŻENIE) — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
