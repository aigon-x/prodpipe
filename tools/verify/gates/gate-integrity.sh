#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/gate-integrity.sh — GATE-001 GATE-INTEGRITY (meta-gate)
# Weryfikuje spójność całego systemu gate'ów:
#   registry == implemented == wired == executed
# oraz brak P0: false gate, shadow gate, orphan gate, unconnected
# check, missing evidence, broken exit code, bypass.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-001 GATE-INTEGRITY (meta-gate) ==="

GATES_DIR="./tools/verify/gates"
DOMAINS_DIR="$GATES_DIR/domains"
REGISTRY="$GATES_DIR/registry.sh"
EVIDENCE_DIR="./artifacts/evidence/gates"

# ── GATE-INTEGRITY-001: registry istnieje i jest parsowalny ─
if [ -f "$REGISTRY" ] && bash -n "$REGISTRY" 2>/dev/null; then
  pass "GATE-INTEGRITY-001 registry parsowalny" BLOCKING "registry.sh istnieje i przechodzi bash -n."
else
  fail "GATE-INTEGRITY-001 registry parsowalny" BLOCKING "registry.sh brak lub błąd składni."
fi

# ── GATE-INTEGRITY-002: registry == implemented ─────────────
# Każdy gate w registry ma odpowiadający skrypt implementacji.
# PROPOSED gate'y są świadomie nie zaimplementowane (lifecycle:
# PROPOSED → IMPLEMENTED) — nie są liczone jako brak implementacji.
if [ -f "$REGISTRY" ]; then
  # shellcheck source=registry.sh
  . "$REGISTRY"
  NOT_IMPLEMENTED=0
  NOT_IMPLEMENTED_DETAIL=""
  for gate_id in $(registry_gate_ids); do
    status="$(registry_field "$gate_id" 22)"
    if [ "$status" = "PROPOSED" ]; then
      continue
    fi
    cmd="$(registry_field "$gate_id" 8)"
    if [ -z "$cmd" ] || [ ! -f "$cmd" ]; then
      NOT_IMPLEMENTED=$((NOT_IMPLEMENTED+1))
      NOT_IMPLEMENTED_DETAIL="$NOT_IMPLEMENTED_DETAIL $gate_id"
    fi
  done
  if [ "$NOT_IMPLEMENTED" -eq 0 ]; then
    pass "GATE-INTEGRITY-002 registry==implemented" BLOCKING "Każdy gate w registry ma skrypt implementacji."
  else
    fail "GATE-INTEGRITY-002 registry==implemented" BLOCKING "$NOT_IMPLEMENTED gate'ów bez implementacji:$NOT_IMPLEMENTED_DETAIL"
  fi
fi

# ── GATE-INTEGRITY-003: brak orphan gate (implementacja bez registry) ─
# Każdy skrypt w domains/ musi mieć wpis w registry.
if [ -f "$REGISTRY" ] && [ -d "$DOMAINS_DIR" ]; then
  # shellcheck source=registry.sh
  . "$REGISTRY"
  ORPHAN=0
  ORPHAN_DETAIL=""
  for f in "$DOMAINS_DIR"/*.sh; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .sh)"
    # Mapuj nazwę pliku na gate_id — szukamy czy jakikolwiek command wskazuje na ten plik.
    found=0
    for gate_id in $(registry_gate_ids); do
      cmd="$(registry_field "$gate_id" 8)"
      if [ "$cmd" = "tools/verify/gates/domains/$base.sh" ]; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 0 ]; then
      ORPHAN=$((ORPHAN+1))
      ORPHAN_DETAIL="$ORPHAN_DETAIL $base"
    fi
  done
  if [ "$ORPHAN" -eq 0 ]; then
    pass "GATE-INTEGRITY-003 brak orphan gate" BLOCKING "Każdy skrypt domains/ ma wpis w registry."
  else
    fail "GATE-INTEGRITY-003 brak orphan gate" BLOCKING "$ORPHAN orphan gate:$ORPHAN_DETAIL"
  fi
fi

# ── GATE-INTEGRITY-004: registry == wired (wszystkie gate'y w profilu) ─
if [ -f "$REGISTRY" ]; then
  # shellcheck source=registry.sh
  . "$REGISTRY"
  NOT_WIRED=0
  NOT_WIRED_DETAIL=""
  for gate_id in $(registry_gate_ids); do
    profile="$(registry_field "$gate_id" 7)"
    if [ -z "$profile" ]; then
      NOT_WIRED=$((NOT_WIRED+1))
      NOT_WIRED_DETAIL="$NOT_WIRED_DETAIL $gate_id"
    fi
  done
  if [ "$NOT_WIRED" -eq 0 ]; then
    pass "GATE-INTEGRITY-004 registry==wired" BLOCKING "Każdy gate ma przypisany profil."
  else
    fail "GATE-INTEGRITY-004 registry==wired" BLOCKING "$NOT_WIRED gate'ów bez profilu:$NOT_WIRED_DETAIL"
  fi
fi

# ── GATE-INTEGRITY-005: registry == executed (każdy gate ma evidence) ─
# Uwaga: meta-gate'y (GATE-001 ten skrypt, GATE-020 evidence, GATE-038 wiring)
# są pomijane — ich evidence jest generowane przez evidence.sh PO uruchomieniu
# tego gate'u (self-referential bootstrap). GATE-001 jest uruchamiany PIERWSZY
# w pętli META_GATES evidence.sh, więc GATE-020 i GATE-038 nie mają jeszcze
# evidence w momencie jego wykonania.
if [ -f "$REGISTRY" ] && [ -d "$EVIDENCE_DIR" ]; then
  # shellcheck source=registry.sh
  . "$REGISTRY"
  NOT_EXECUTED=0
  NOT_EXECUTED_DETAIL=""
  for gate_id in $(registry_gate_ids); do
    # Bootstrap: pomijamy meta-gate'y (GATE-001 sam siebie, GATE-020 evidence,
    # GATE-038 wiring) — ich evidence generowane po uruchomieniu tego gate'u.
    if [ "$gate_id" = "GATE-001" ] || [ "$gate_id" = "GATE-020" ] || [ "$gate_id" = "GATE-038" ]; then
      continue
    fi
    # PROPOSED gate'y nie mają implementacji, więc nie mają evidence —
    # to nie jest missing evidence (lifecycle: PROPOSED z definicji nie jest wykonany).
    status="$(registry_field "$gate_id" 22)"
    if [ "$status" = "PROPOSED" ]; then
      continue
    fi
    if [ ! -f "$EVIDENCE_DIR/$gate_id.evidence" ]; then
      NOT_EXECUTED=$((NOT_EXECUTED+1))
      NOT_EXECUTED_DETAIL="$NOT_EXECUTED_DETAIL $gate_id"
    fi
  done
  if [ "$NOT_EXECUTED" -eq 0 ]; then
    pass "GATE-INTEGRITY-005 registry==executed" BLOCKING "Każdy gate ma evidence wykonania."
  else
    fail "GATE-INTEGRITY-005 registry==executed" BLOCKING "$NOT_EXECUTED gate'ów bez evidence:$NOT_EXECUTED_DETAIL"
  fi
fi

# ── GATE-INTEGRITY-006: brak broken exit code w skryptach ───
# Każdy skrypt implementacji musi kończyć się verify_module_exit.
BROKEN_EXIT=0
BROKEN_EXIT_DETAIL=""
for f in "$DOMAINS_DIR"/*.sh "$GATES_DIR"/gate-integrity.sh; do
  [ -e "$f" ] || continue
  if ! grep -q 'verify_module_exit' "$f" 2>/dev/null; then
    BROKEN_EXIT=$((BROKEN_EXIT+1))
    BROKEN_EXIT_DETAIL="$BROKEN_EXIT_DETAIL $(basename "$f")"
  fi
done
if [ "$BROKEN_EXIT" -eq 0 ]; then
  pass "GATE-INTEGRITY-006 brak broken exit code" BLOCKING "Wszystkie skrypty kończą się verify_module_exit."
else
  fail "GATE-INTEGRITY-006 brak broken exit code" BLOCKING "$BROKEN_EXIT skryptów bez verify_module_exit:$BROKEN_EXIT_DETAIL"
fi

# ── GATE-INTEGRITY-007: brak bypass (|| true, set +e, continue-on-error) ─
# Wykrywa RZECZYWISTE użycie bypass w kodzie wykonawczym, ignorując:
#   - komentarze (linie zaczynające się od #)
#   - linie grep, które tylko DETEKTUJĄ te wzorce (legalne — to nie użycie)
BYPASS=0
BYPASS_DETAIL=""
for f in "$DOMAINS_DIR"/*.sh "$GATES_DIR"/gate-integrity.sh; do
  [ -e "$f" ] || continue
  # Szukamy wzorców bypass w liniach, które NIE są komentarzami i NIE zawierają grep.
  if grep -vE '^\s*#' "$f" 2>/dev/null | grep -vE 'grep' | grep -qE '\|\|\s*true|set\s+\+e|continue-on-error'; then
    BYPASS=$((BYPASS+1))
    BYPASS_DETAIL="$BYPASS_DETAIL $(basename "$f")"
  fi
done
if [ "$BYPASS" -eq 0 ]; then
  pass "GATE-INTEGRITY-007 brak bypass" BLOCKING "Brak wzorcow bypass (or-true, set-plus-e, ci-on-error) w skryptach."
else
  fail "GATE-INTEGRITY-007 brak bypass" BLOCKING "$BYPASS skryptów z bypass:$BYPASS_DETAIL"
fi

verify_module_exit
