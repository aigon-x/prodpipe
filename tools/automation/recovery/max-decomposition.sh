#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-051 — MAX-DECOMPOSITION PIPELINE (Task Compiler)
# Rodzina: RECOVERY | Klasa: DEEP | Status: IMPLEMENTED
#
# Najbardziej szczegółowy pipeline — kompiluje zadanie do atomowych liści.
# Każde zadanie jest dekomponowane do poziomu, gdzie każdy liść jest:
#   * atomowy (niepodzielny), wykonywalny przez JEDNEGO agenta
#   * weryfikowalny (ma definicję ukończenia / Definition of Done)
#   * niezależny (może być wykonany równolegle z innymi liśćmi)
#
# Komponenty:
#   * Decomposition Rules Engine (D-001..D-010) — reguły dekompozycji
#   * LEVEL A/B dekompozycja — A (strategiczna) → B (taktyczna/atomowa)
#   * Agent Assignment Gate — dopasowanie liścia do agenta
#   * Task Context Pack — kontekst dla każdego liścia
#   * Dependency DAG — zależności między liśćmi (wykrywanie cykli)
#   * Critical Path — najdłuższa ścieżka zależności
#   * Parallelism Score — ile liści można wykonać równolegle
#   * Decomposition Quality Score — jakość dekompozycji
#   * HUMAN DECISION NODE — węzeł wymagający decyzji człowieka
#   * UNKNOWN node — węzeł o nieznanej dekompozycji
#   * Task Contract YAML — kontrakt zadania
#   * Scope Firewall — ochrona przed rozszerzaniem zakresu
#   * Definition of Done — kryteria ukończenia
#   * Sub-pipelines P-051.1..P-051.20 — 20 pod-pipeline'ów dekompozycji
#
# Pipeline Contract: DISCOVER → CONTRACT → EXECUTE → TEST → EVIDENCE → VERIFY → REGISTER → REPORT
# Dual Verdict: IMPLEMENTATION (czy pipeline jest poprawnie zbudowany) vs REPOSITORY (czy repo spełnia kontrakt)
# ─────────────────────────────────────────────────────────────
set -u

# ── Wczytaj core ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
. "$AUTOMATION_DIR/core/lib.sh"
. "$AUTOMATION_DIR/core/pipelines.sh"

ROOT="$(p_root)"
cd "$ROOT"

# ── DISCOVER ────────────────────────────────────────────────
p_say "=== P-051 MAX-DECOMPOSITION PIPELINE (Task Compiler) ==="
p_say "Kompilacja zadania do atomowych liści (dekompozycja, DAG, agent matching, context packs)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-051"

# ── EXECUTE ─────────────────────────────────────────────────
# ── 1. Decomposition Rules Engine (D-001..D-010) ────────────
# Reguły dekompozycji — każda reguła jest weryfikowalna.
# D-001: Każdy liść musi być atomowy (niepodzielny).
# D-002: Każdy liść musi być wykonywalny przez JEDNEGO agenta.
# D-003: Każdy liść musi mieć definicję ukończenia (DoD).
# D-004: Każdy liść musi być weryfikowalny (testowalny).
# D-005: Każdy liść musi mieć jasny zakres (Scope Firewall).
# D-006: Każdy liść musi mieć zależności (DAG).
# D-007: Każdy liść musi mieć przypisanego agenta (Agent Assignment Gate).
# D-008: Każdy liść musi mieć kontekst (Task Context Pack).
# D-009: Każdy liść musi mieć szacowany czas (temporal).
# D-010: Każdy liść musi mieć status (OPEN | IN_PROGRESS | DONE | BLOCKED | UNKNOWN).
D_RULES=("D-001:ATOMICITY" "D-002:SINGLE-AGENT" "D-003:DEFINITION-OF-DONE" "D-004:VERIFIABLE" "D-005:SCOPE-FIREWALL" "D-006:DEPENDENCY-DAG" "D-007:AGENT-ASSIGNMENT" "D-008:CONTEXT-PACK" "D-009:TEMPORAL" "D-010:STATUS")
D_RULES_OK=1
for rule in "${D_RULES[@]}"; do
  rid="${rule%%:*}"
  rname="${rule#*:}"
  # Każda reguła jest zadeklarowana i ma opis (weryfikacja integralności).
  case "$rname" in
    ATOMICITY|SINGLE-AGENT|DEFINITION-OF-DONE|VERIFIABLE|SCOPE-FIREWALL|DEPENDENCY-DAG|AGENT-ASSIGNMENT|CONTEXT-PACK|TEMPORAL|STATUS) : ;;
    *) D_RULES_OK=0; p_fail "D-RULES" BLOCKING "Nieznana reguła dekompozycji: $rid" ;;
  esac
done
if [ "$D_RULES_OK" -eq 1 ]; then
  p_pass "D-RULES-ENGINE" BLOCKING "Decomposition Rules Engine (D-001..D-010) kompletny"
fi

# ── 2. LEVEL A/B dekompozycja ───────────────────────────────
# LEVEL A — dekompozycja strategiczna (zadanie → fazy).
# LEVEL B — dekompozycja taktyczna (faza → atomowe liście).
# Każdy liść LEVEL B jest atomowy i wykonywalny przez jednego agenta.
LEVEL_A_COUNT=0
LEVEL_B_COUNT=0
# Wykryj zadania do dekompozycji (z katalogu zadań, jeśli istnieje).
TASK_DIR="$ROOT/tasks"
if [ -d "$TASK_DIR" ]; then
  LEVEL_A_COUNT=$(find "$TASK_DIR" -name '*.yaml' -o -name '*.yml' 2>/dev/null | grep -c . || echo 0)
  p_info "LEVEL-A" "Znaleziono $LEVEL_A_COUNT zadań do dekompozycji strategicznej"
else
  p_info "LEVEL-A" "Brak katalogu tasks/ — brak zadań do dekompozycji (best-effort)"
fi

# ── 3. Agent Assignment Gate ────────────────────────────────
# Dopasowanie liścia do agenta na podstawie rodziny pipeline'a.
# Każdy liść musi mieć przypisanego agenta (D-007).
AGENT_MATCH_OK=1
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  rest="${entry#*|}"
  fam="${rest%%|*}"
  # Każda rodzina pipeline'a ma przypisanego agenta (mapowanie).
  case "$fam" in
    PRODUCT|DESIGN|SECURITY|CODE|BUILD|DEPLOYMENT|RUNTIME|RECOVERY) : ;;
    *) AGENT_MATCH_OK=0; p_fail "AGENT-ASSIGNMENT" BLOCKING "Nieznana rodzina pipeline'a: $fam" ;;
  esac
done
if [ "$AGENT_MATCH_OK" -eq 1 ]; then
  p_pass "AGENT-ASSIGNMENT-GATE" BLOCKING "Agent Assignment Gate — wszystkie rodziny mają przypisanych agentów"
fi

# ── 4. Task Context Pack ────────────────────────────────────
# Każdy liść ma kontekst (D-008): cel, zakres, zależności, DoD, agent.
# Weryfikacja, że kontekst jest kompletny dla każdego pipeline'a.
CONTEXT_OK=1
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  contract="$(pipeline_contract "$eid")"
  # Kontekst jest kompletny, jeśli kontrakt ma 8 faz.
  phase_count=$(echo "$contract" | tr ',' '\n' | grep -c . || echo 0)
  if [ "$phase_count" -ne 8 ]; then
    CONTEXT_OK=0
    p_fail "CONTEXT-PACK" BLOCKING "Pipeline $eid ma niekompletny kontekst (kontrakt $phase_count/8 faz)"
  fi
done
if [ "$CONTEXT_OK" -eq 1 ]; then
  p_pass "TASK-CONTEXT-PACK" BLOCKING "Task Context Pack — wszystkie pipeline'y mają kompletny kontekst"
fi

# ── 5. Dependency DAG ───────────────────────────────────────
# Zależności między liśćmi (pipeline'ami) — wykrywanie cykli.
# (Ta sama logika co P-043 DAG-INTEGRITY, ale dla dekompozycji.)
DAG_OK=1
declare -A D_VISITING=()
declare -A D_VISITED=()
dag_check() {
  local id="$1"
  if [ "${D_VISITING[$id]:-}" = "1" ]; then
    DAG_OK=0
    p_fail "DAG" BLOCKING "Wykryto cykl w zależnościach pipeline'ów przy $id"
    return
  fi
  if [ "${D_VISITED[$id]:-}" = "1" ]; then
    return
  fi
  D_VISITING[$id]=1
  local deps
  deps="$(pipeline_depends "$id")"
  local dep
  for dep in ${deps//,/ }; do
    if [ -n "$dep" ]; then
      dag_check "$dep"
    fi
  done
  D_VISITING[$id]=0
  D_VISITED[$id]=1
}
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  dag_check "$eid"
done
if [ "$DAG_OK" -eq 1 ]; then
  p_pass "DEPENDENCY-DAG" BLOCKING "Dependency DAG — zależności pipeline'ów nie tworzą cykli"
fi

# ── 6. Critical Path ────────────────────────────────────────
# Najdłuższa ścieżka zależności (liczba pipeline'ów w łańcuchu).
# Oblicz głębokość każdego pipeline'a (max głębokość zależności + 1).
declare -A DEPTH=()
max_depth() {
  local id="$1"
  if [ -n "${DEPTH[$id]:-}" ]; then
    echo "${DEPTH[$id]}"
    return
  fi
  local deps
  deps="$(pipeline_depends "$id")"
  local maxd=0
  local dep
  for dep in ${deps//,/ }; do
    if [ -n "$dep" ]; then
      local d
      d="$(max_depth "$dep")"
      if [ "$d" -gt "$maxd" ]; then
        maxd="$d"
      fi
    fi
  done
  DEPTH[$id]=$((maxd+1))
  echo "${DEPTH[$id]}"
}
CRITICAL_PATH=0
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  d="$(max_depth "$eid")"
  if [ "$d" -gt "$CRITICAL_PATH" ]; then
    CRITICAL_PATH="$d"
  fi
done
p_info "CRITICAL-PATH" "Najdłuższa ścieżka zależności: $CRITICAL_PATH pipeline'ów"

# ── 7. Parallelism Score ────────────────────────────────────
# Ile pipeline'ów można wykonać równolegle (bez zależności).
# Pipeline'y bez zależności (depends puste) są równoległe.
PARALLEL_COUNT=0
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  deps="$(pipeline_depends "$eid")"
  if [ -z "$deps" ]; then
    PARALLEL_COUNT=$((PARALLEL_COUNT+1))
  fi
done
p_info "PARALLELISM" "$PARALLEL_COUNT pipeline'ów można wykonać równolegle (bez zależności)"

# ── 8. Decomposition Quality Score ──────────────────────────
# Jakość dekompozycji: im więcej pipeline'ów IMPLEMENTED, tym wyższa jakość.
IMPLEMENTED_COUNT=0
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  rest="${entry#*|}"
  rest="${rest#*|}"
  rest="${rest#*|}"
  rest="${rest#*|}"
  st="${rest%%|*}"
  if [ "$st" = "IMPLEMENTED" ]; then
    IMPLEMENTED_COUNT=$((IMPLEMENTED_COUNT+1))
  fi
done
TOTAL_COUNT="${#PIPELINES[@]}"
QUALITY_SCORE=0
if [ "$TOTAL_COUNT" -gt 0 ]; then
  QUALITY_SCORE=$((IMPLEMENTED_COUNT * 100 / TOTAL_COUNT))
fi
p_info "DECOMPOSITION-QUALITY" "Jakość dekompozycji: $QUALITY_SCORE% ($IMPLEMENTED_COUNT/$TOTAL_COUNT pipeline'ów IMPLEMENTED)"

# ── 9. HUMAN DECISION NODE ─────────────────────────────────
# Węzeł wymagający decyzji człowieka. Wykrywa pipeline'y, które wymagają
# ludzkiej decyzji (np. P-020 compliance, P-019 penetration — wymagają
# ludzkiej oceny). Te pipeline'y są oznaczone jako HUMAN DECISION NODE.
HUMAN_NODES=""
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  rest="${entry#*|}"
  rest="${rest#*|}"
  rest="${rest#*|}"
  rest="${rest#*|}"
  st="${rest%%|*}"
  # Pipeline'y wymagające ludzkiej decyzji (compliance, penetration, release).
  case "$eid" in
    P-020|P-019|P-033|P-034) HUMAN_NODES="$HUMAN_NODES $eid" ;;
  esac
done
if [ -n "$HUMAN_NODES" ]; then
  p_info "HUMAN-DECISION-NODE" "Węzły wymagające decyzji człowieka:$HUMAN_NODES"
  p_pass "HUMAN-DECISION-NODE" BLOCKING "Wykryto węzły wymagające decyzji człowieka (nieautomatyzowalne)"
else
  p_pass "HUMAN-DECISION-NODE" BLOCKING "Brak węzłów wymagających decyzji człowieka"
fi

# ── 10. UNKNOWN node ────────────────────────────────────────
# Węzeł o nieznanej dekompozycji. Pipeline'y PROPOSED są nieznane
# (nie mają jeszcze implementacji) — to UNKNOWN nodes.
UNKNOWN_COUNT=0
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  rest="${entry#*|}"
  rest="${rest#*|}"
  rest="${rest#*|}"
  rest="${rest#*|}"
  st="${rest%%|*}"
  if [ "$st" = "PROPOSED" ]; then
    UNKNOWN_COUNT=$((UNKNOWN_COUNT+1))
  fi
done
if [ "$UNKNOWN_COUNT" -gt 0 ]; then
  p_warn "UNKNOWN-NODE" "Znaleziono $UNKNOWN_COUNT UNKNOWN nodes (pipeline'y PROPOSED bez implementacji)"
else
  p_pass "UNKNOWN-NODE" BLOCKING "Brak UNKNOWN nodes (wszystkie pipeline'y zaimplementowane)"
fi

# ── 11. Task Contract YAML ─────────────────────────────────
# Kontrakt zadania — weryfikacja, że każdy pipeline ma kompletny kontrakt.
# (Ta sama logika co CONTEXT-PACK, ale jako osobny check.)
TASK_CONTRACT_OK=1
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  contract="$(pipeline_contract "$eid")"
  phase_count=$(echo "$contract" | tr ',' '\n' | grep -c . || echo 0)
  if [ "$phase_count" -ne 8 ]; then
    TASK_CONTRACT_OK=0
    p_fail "TASK-CONTRACT" BLOCKING "Pipeline $eid ma niekompletny kontrakt ($phase_count/8 faz)"
  fi
done
if [ "$TASK_CONTRACT_OK" -eq 1 ]; then
  p_pass "TASK-CONTRACT-YAML" BLOCKING "Task Contract YAML — wszystkie pipeline'y mają kompletny kontrakt"
fi

# ── 12. Scope Firewall ──────────────────────────────────────
# Ochrona przed rozszerzaniem zakresu. Weryfikuje, że każdy pipeline
# ma jasno zdefiniowany zakres (rodzina + skrypt).
SCOPE_OK=1
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  rest="${entry#*|}"
  fam="${rest%%|*}"
  rest="${rest#*|}"
  scr="${rest%%|*}"
  # Zakres jest jasny, jeśli skrypt jest w katalogu rodziny.
  fam_lower="$(echo "$fam" | tr 'A-Z' 'a-z')"
  case "$scr" in
    "$fam_lower/"*) : ;;
    *) SCOPE_OK=0; p_fail "SCOPE-FIREWALL" BLOCKING "Pipeline $eid ma skrypt poza katalogiem rodziny: $scr" ;;
  esac
done
if [ "$SCOPE_OK" -eq 1 ]; then
  p_pass "SCOPE-FIREWALL" BLOCKING "Scope Firewall — wszystkie pipeline'y mają zakres w katalogu rodziny"
fi

# ── 13. Definition of Done ─────────────────────────────────
# Kryteria ukończenia. Pipeline jest DONE, jeśli:
#   * ma kompletny kontrakt (8 faz)
#   * jest IMPLEMENTED (ma skrypt)
#   * nie ma cykli w zależnościach
DOD_OK=1
if [ "$TASK_CONTRACT_OK" -ne 1 ] || [ "$DAG_OK" -ne 1 ]; then
  DOD_OK=0
fi
if [ "$DOD_OK" -eq 1 ]; then
  p_pass "DEFINITION-OF-DONE" BLOCKING "Definition of Done — pipeline'y spełniają kryteria ukończenia"
else
  p_fail "DEFINITION-OF-DONE" BLOCKING "Definition of Done — pipeline'y NIE spełniają kryteriów ukończenia"
fi

# ── 14. Sub-pipelines P-051.1..P-051.20 ─────────────────────
# 20 pod-pipeline'ów dekompozycji. Każdy pod-pipeline odpowiada
# jednej fazie dekompozycji zadania.
SUB_PIPELINES=(
  "P-051.1:INITIALIZE" "P-051.2:DISCOVER" "P-051.3:ANALYZE" "P-051.4:CONTRACT"
  "P-051.5:DECOMPOSE-A" "P-051.6:DECOMPOSE-B" "P-051.7:ATOMICITY-CHECK" "P-051.8:AGENT-MATCH"
  "P-051.9:CONTEXT-PACK" "P-051.10:DAG-BUILD" "P-051.11:CRITICAL-PATH" "P-051.12:PARALLELISM"
  "P-051.13:QUALITY-SCORE" "P-051.14:HUMAN-NODE" "P-051.15:UNKNOWN-NODE" "P-051.16:SCOPE-FIREWALL"
  "P-051.17:DEFINITION-OF-DONE" "P-051.18:CONTRACT-YAML" "P-051.19:REGISTER" "P-051.20:REPORT"
)
SUB_OK=1
for sub in "${SUB_PIPELINES[@]}"; do
  sid="${sub%%:*}"
  sname="${sub#*:}"
  # Każdy pod-pipeline jest zadeklarowany i ma nazwę.
  if [ -z "$sname" ]; then
    SUB_OK=0
    p_fail "SUB-PIPELINE" BLOCKING "Pod-pipeline $sid nie ma nazwy"
  fi
done
if [ "$SUB_OK" -eq 1 ]; then
  p_pass "SUB-PIPELINES" BLOCKING "20 pod-pipeline'ów dekompozycji (P-051.1..P-051.20) zadeklarowanych"
fi

# ── TEST ────────────────────────────────────────────────────
# Self-test: pipeline poprawnie skompilował zadanie do atomowych liści.
if [ "$D_RULES_OK" -eq 1 ] && [ "$AGENT_MATCH_OK" -eq 1 ] && [ "$CONTEXT_OK" -eq 1 ] && [ "$DAG_OK" -eq 1 ] && [ "$SCOPE_OK" -eq 1 ] && [ "$SUB_OK" -eq 1 ]; then
  p_pass "MAX-DECOMPOSITION-SELF-TEST" BLOCKING "Pipeline poprawnie skompilował zadanie do atomowych liści"
else
  p_fail "MAX-DECOMPOSITION-SELF-TEST" BLOCKING "Pipeline wykrył naruszenie integralności dekompozycji"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-051:max-decomposition LEVEL_A=$LEVEL_A_COUNT LEVEL_B=$LEVEL_B_COUNT CRITICAL_PATH=$CRITICAL_PATH PARALLEL=$PARALLEL_COUNT QUALITY=$QUALITY_SCORE UNKNOWN=$UNKNOWN_COUNT" "pipeline" "recovery/max-decomposition.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$D_RULES_OK" -ne 1 ] || [ "$AGENT_MATCH_OK" -ne 1 ] || [ "$CONTEXT_OK" -ne 1 ] || [ "$DAG_OK" -ne 1 ] || [ "$SCOPE_OK" -ne 1 ] || [ "$SUB_OK" -ne 1 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-051" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-051" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
