# PROD-READY-EXECUTOR-MODEL

> **Etap 1: DISCOVER + AUDIT** — raport deliverable (masterprompt §37).
> Data: 2026-08-10. Metoda: READ-ONLY audyt przez 4 równoległe subagenty Explore.
> Źródła prawdy: `tools/automation/automation.sh`, `tools/automation/core/pipelines.sh`, `tools/verify/gates/enforcement.sh`, `tools/verify/verify.sh`, `tools/automation/monitor/monitor.sh`.

## 1. Trzy równoległe światy wykonawcze

Platforma ma **trzy niezależne systemy wykonawcze**, które współdzielą StateStore jako magazyn evidence, ale NIE mają wspólnego wykonawczego orchestratora:

| Świat | Orchestrator | Jednostka | Taksonomia | Entry pointy |
|---|---|---|---|---|
| **PIPELINE OS** | `tools/automation/automation.sh` | pipeline'y P-XXX | klasy FAST/STANDARD/DEEP/RELEASE/CONTINUOUS | manual / `verify.sh pipelines` (martwe) |
| **GATE system** | `tools/verify/verify.sh` + `enforcement.sh` | gate'y GATE-XXX | profile LOCAL_FAST/PRE_PUSH/CI/RELEASE | hooki + CI + manual |
| **MONITOR PLANE** | `tools/automation/monitor/monitor.sh` | lifecycle pipeline'ów + gate'y MON-* | MON-* | manual |

**Wspólny fundament:** StateStore (tabela `evidence`, funkcje `p_evidence`/`evidence_record` z `core/lib.sh`). Ale to wspólny magazyn danych, NIE wspólny orchestrator — każdy system zapisuje evidence niezależnie; żaden nie czyta evidence drugiego, by sterować wykonaniem.

## 2. EXECUTOR MODEL — pipeline'y (PIPELINE OS)

### 2.1 Cykl życia (8 faz kontraktu)

Kontrakt 8 faz (DISCOVER→CONTRACT→EXECUTE→TEST→EVIDENCE→VERIFY→REGISTER→REPORT) jest **deklarowany w metadanych** (pipelines.yaml, pole `contract`), ale **NIE jest egzekwowany przez orchestrator**. `automation.sh` nie sprawdza faz — po prostu uruchamia skrypt pipeline'u i sprawdza exit code.

### 2.2 Wybór pipeline'ów

Wybór odbywa się **per klasa** (FAST/STANDARD/DEEP/RELEASE/CONTINUOUS), nie per family. `automation.sh` mapuje subkomendę na klasy:
- `verify` → FAST + STANDARD
- `audit` → DEEP
- `release` → RELEASE
- `deploy` → RELEASE + DEEP
- `certify` → CONTINUOUS

Lista pipeline'ów dla klasy jest w `pipeline_class_modules()` (pipelines.sh, linie 280-300) — np. `FAST` → `P-016 P-021 P-024 P-025`.

### 2.3 Rozwiązywanie zależności (DAG)

`automation.sh` implementuje **topologiczne sortowanie z wykrywaniem cykli** przez `run_pipeline_dag()` (linie 88-116):
```bash
run_pipeline_dag() {
  local id="$1"
  if [ "${PIPE_VISITING[$id]:-}" = "1" ]; then
    PIPE_FAIL_COUNT=$((PIPE_FAIL_COUNT+1))
    p_fail "pipeline $id" BLOCKING "Wykryto cykl w zależnościach pipeline'ów (DAG)."
    return 1
  fi
  ...
  deps="$(pipeline_depends "$id")"
  for dep in ${deps//,/ }; do
    if [ -n "$dep" ]; then run_pipeline_dag "$dep"; fi
  done
  ...
  run_pipeline "$id"
}
```
Zależności pochodzą z pola `depends` (np. P-002 depends P-001).

### 2.4 Wykonanie i evidence

`run_pipeline()` (linie 48-86):
- PROPOSED pipeline'y są pomijane (tylko rejestrowane).
- **FAIL-CLOSED:** pipeline zadeklarowany a nieistniejący = FAIL (BLOCKING), nigdy skip.
- Po wykonaniu zapisuje evidence przez `p_evidence "pipeline:$id:rc=$rc" "pipeline" "$script"` (evidence bridge P0#1).
- Rejestruje `pipeline_run` przez `p_register_run "$id" ...`.

### 2.5 Raportowanie wyniku

Na końcu `automation.sh`:
- `p_evidence_complete "$PIPE_RUN_COUNT"` — meta-gate PIPELINE-EVIDENCE-COMPLETE (każdy pipeline musi mieć evidence).
- `p_module_exit` — propaguje exit code (0=PASS, 1=FAIL) do procesu nadrzędnego.

## 3. EXECUTOR MODEL — gate'y (GATE system)

### 3.1 Wybór gate'ów per profil

`enforcement.sh` (linie 40-46) pobiera listę gate'ów przez `registry_gates_for_profile "$PROFILE"` (registry.sh, linie 578-590):
```bash
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
```
RELEASE jest nadzbiorem — gate'y RELEASE działają we wszystkich profilach.

### 3.2 Uruchamianie

`enforcement.sh` (linie 48-82) iteruje po gate'ach:
- PROPOSED gate'y są pomijane (widoczne w raportach, nie egzekwowane).
- **FAIL-CLOSED:** gate zadeklarowany a nieistniejący = FAIL (BLOCKING).
- Każdy gate uruchamiany przez `bash "$cmd"`, exit code przechwytywany.

### 3.3 Agregacja wyniku

`GATE_FAIL` licznik inkrementowany przy każdym FAIL. Na końcu:
```bash
if [ "$GATE_FAIL" -eq 0 ]; then
  sayc "ENFORCEMENT: PASS (profil $PROFILE)" "$C_GREEN"
else
  sayc "ENFORCEMENT: FAIL ($GATE_FAIL gate'ów z FAIL)" "$C_RED"
fi
verify_module_exit
```

### 3.4 Evidence i exit code

- Evidence zapisywane przez `fail`/`pass` (z core/lib.sh) do StateStore.
- `verify_module_exit` propaguje exit code (0=PASS, 1=FAIL) do procesu nadrzędnego (hook/CI).

### 3.5 verify.sh jako nadrzędny orchestrator gate'ów

`verify.sh gates <PROFILE>` (linie 168-192) uruchamia:
1. `enforcement.sh <PROFILE>` — egzekwowanie gate'ów.
2. `gate-integrity.sh` — meta-gate GATE-001 (registry==implemented==wired==executed).

## 4. EXECUTOR MODEL — Monitor Plane

`tools/automation/monitor/monitor.sh` — lifecycle pipeline'ów (register/schedule/queue/start/control/complete/notify/archive) + gate'y MON-*. Uruchamiany tylko manualnie. Nie jest podpięty do hooków/CI.

## 5. Wspólny orchestrator — NIE istnieje

**NIE istnieje wspólny orchestrator łączący pipeline'y + gate'y + evidence + raporty w jednym przebiegu.**

- `verify.sh` jest orchestratorem **tylko dla GATE systemu** (subkomendy reconcile/drift/history/debt/waivers/gates/config). Ma subkomendę `pipelines`, ale jest ona **martwa** (nie wywoływana nigdzie).
- `automation.sh` jest orchestratorem **tylko dla PIPELINE systemu** (klasy FAST..CONTINUOUS).
- `monitor.sh` jest orchestratorem **tylko dla Monitor Plane** (lifecycle pipeline'ów + gate'y MON-*).

Te trzy systemy mają **wspólny fundament evidence** (StateStore, tabela `evidence`, funkcje `p_evidence`/`evidence_record` z core/lib.sh) — ale to wspólny magazyn danych, NIE wspólny orchestrator wykonawczy.

## 6. Rekomendacja (do Etapu 2)

Zbudować **wspólny orchestrator** (np. rozszerzenie `verify.sh` o subkomendę `all` uruchamiającą gate'y + pipeline'y + monitor w jednym przebiegu, z jawnym mapowaniem klasa↔profil i pipeline↔gate) oraz podpiąć go do hooków/CI. Szczegóły w PROD-READY-GAP-ANALYSIS.md.
