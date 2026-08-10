#!/usr/bin/env bash
# ============================================================================
# test-config-gates.sh — Config Plane Gates (CFG-001..008)
# ============================================================================
# Weryfikuje, że:
#   T1: CFG-002 — registry.yaml ma poprawną strukturę (schema_version, defaults, floors)
#   T2: CFG-005 — default >= floor dla wszystkich kluczy
#   T3: CFG-006 — wszystkie waivery mają expires_at
#   T4: CFG-008 — klucze niekonfigurowalne nie są konfigurowalne
#
# Odporność: jeśli registry.yaml nie istnieje, testy oczekują FAIL (fail-closed).
#
# Użycie: ./test-config-gates.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$VERIFY_DIR/../.." && pwd)"
REGISTRY="$REPO_ROOT/config/canonical/registry.yaml"
EXEMPTIONS="$REPO_ROOT/config/canonical/config_exemptions.yaml"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== CONFIG GATES TESTS ==="

# --- T1: CFG-002 — registry.yaml ma poprawną strukturę ----------------------
echo ""
echo "--- T1: CFG-002 — registry.yaml struktura (schema_version, gates) ---"
if [ ! -f "$REGISTRY" ]; then
    t_fail "Brak registry.yaml ($REGISTRY) — fail-closed: CFG-002 oczekuje FAIL"
else
    if python3 - "$REGISTRY" <<'PYEOF' >/dev/null 2>&1
import sys, yaml
with open(sys.argv[1]) as f:
    d = yaml.safe_load(f) or {}
assert isinstance(d, dict), "registry nie jest mapą"
assert "schema_version" in d, "brak schema_version"
assert "gates" in d, "brak gates"
PYEOF
    then
        t_pass "registry.yaml ma schema_version, gates"
    else
        t_fail "registry.yaml nie ma poprawnej struktury (schema_version/gates)"
    fi
fi

# --- T2: CFG-005 — default >= floor dla wszystkich kluczy -------------------
echo ""
echo "--- T2: CFG-005 — default >= floor dla wszystkich kluczy ---"
if [ ! -f "$REGISTRY" ]; then
    t_fail "Brak registry.yaml — fail-closed: CFG-005 oczekuje FAIL"
else
    BELOW="$(python3 - "$REGISTRY" <<'PYEOF'
import sys, yaml
with open(sys.argv[1]) as f:
    d = yaml.safe_load(f) or {}
gates = d.get("gates") or {}
n = 0
for k, dv in gates.items():
    if isinstance(dv, dict):
        floor = dv.get("floor")
        default = dv.get("default")
    else:
        floor = None
        default = dv
    if floor is None or default is None:
        continue
    try:
        if float(default) < float(floor):
            n += 1
    except (TypeError, ValueError):
        pass
print(n)
PYEOF
)"
    if [ "$BELOW" -eq 0 ]; then
        t_pass "Wszystkie defaulty >= floor"
    else
        t_fail "$BELOW kluczy z defaultem poniżej floora"
    fi
fi

# --- T3: CFG-006 — wszystkie waivery mają expires_at ------------------------
echo ""
echo "--- T3: CFG-006 — wszystkie waivery mają expires_at ---"
if [ ! -f "$REGISTRY" ]; then
    t_fail "Brak registry.yaml — fail-closed: CFG-006 oczekuje FAIL"
else
    NODATE="$(python3 - "$REGISTRY" <<'PYEOF'
import sys, yaml
with open(sys.argv[1]) as f:
    d = yaml.safe_load(f) or {}
w = d.get("waivers") or []
n = 0
for item in w:
    if not item.get("expires_at"):
        n += 1
print(n)
PYEOF
)"
    if [ "$NODATE" -eq 0 ]; then
        t_pass "Wszystkie waivery mają expires_at"
    else
        t_fail "$NODATE waiverów bez expires_at"
    fi
fi

# --- T4: CFG-008 — klucze niekonfigurowalne nie są konfigurowalne -----------
echo ""
echo "--- T4: CFG-008 — klucze niekonfigurowalne nie są konfigurowalne ---"
if [ ! -f "$REGISTRY" ]; then
    t_fail "Brak registry.yaml — fail-closed: CFG-008 oczekuje FAIL"
elif [ ! -f "$EXEMPTIONS" ]; then
    # Brak config_exemptions.yaml = brak zdefiniowanych kluczy niekonfigurowalnych.
    t_pass "Brak config_exemptions.yaml — brak kluczy niekonfigurowalnych do naruszenia"
else
    VIOL="$(python3 - "$REGISTRY" "$EXEMPTIONS" <<'PYEOF'
import sys, yaml
with open(sys.argv[1]) as f:
    reg = yaml.safe_load(f) or {}
with open(sys.argv[2]) as f:
    ex = yaml.safe_load(f) or {}
exempt = []
for section in ("exemptions", "root_bootstrap", "keys"):
    items = ex.get(section) or []
    if isinstance(items, dict):
        exempt.extend(items.keys())
    else:
        for item in items:
            if isinstance(item, dict):
                k = item.get("key")
                if k:
                    exempt.append(k)
            else:
                exempt.append(item)
defaults = reg.get("gates") or {}
floors = reg.get("gates") or {}
if isinstance(floors, list):
    floors = {k: v for k, v in floors}
n = 0
for k in exempt:
    if k in defaults or k in floors:
        n += 1
print(n)
PYEOF
)"
    if [ "$VIOL" -eq 0 ]; then
        t_pass "Żaden klucz niekonfigurowalny nie jest konfigurowalny"
    else
        t_fail "$VIOL kluczy niekonfigurowalnych w gates"
    fi
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== CONFIG GATES — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
