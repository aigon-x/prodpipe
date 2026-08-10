# PROD-READY-CONNECTION-MATRIX

> **Etap 1: DISCOVER + AUDIT** — raport deliverable (masterprompt §37).
> Data: 2026-08-10. Metoda: READ-ONLY audyt przez 4 równoległe subagenty Explore.
> Źródła prawdy: `config/canonical/pipelines.yaml`, `config/canonical/gates.yaml`, `tools/verify/gates/registry.sh`, `tools/verify/verify.sh`, `tools/automation/automation.sh`, `.git-hooks/`, `.github/workflows/`, `docs/graphs/traceability.mmd`.

## 1. Finding krytyczny: pipeline'y i gate'y to DWA OSOBNE ŚWIATY

**Pipeline'y (P-XXX) i gate'y (GATE-XXX) NIE mają jawnego, wykonawczego połączenia.** To najważniejsze finding audytu.

### 1.1 Czy pipelines.yaml / pipelines.sh odwołuje się do GATE-XXX?

**NIE.** `config/canonical/pipelines.yaml` i wygenerowany `tools/automation/core/pipelines.sh` NIE zawierają żadnego odwołania do gate'ów GATE-XXX z registry.

- `pipelines.yaml` zawiera wyłącznie własne gate'y **MON-*** (Monitor Plane) w sekcji `monitor_plane.gates` (MON-R/S/Q/ST/M/C/CO/N/A × 8 = 70 gate'ów). To metadane lifecycle pipeline'ów, NIE gate'y z `tools/verify/gates/registry.sh`.
- `pipelines.sh` — grep `GATE-|gate` zwrócił tylko 2 nieistotne trafienia (komentarz "FALSE GATE" i literały w nazwach skryptów). Zero odwołań do GATE-XXX.

### 1.2 Czy registry.sh / gates.yaml odwołuje się do P-XXX?

**Częściowo, ale tylko opisowo (weryfikacyjnie), NIE wykonawczo.**

- `config/canonical/gates.yaml` — grep `P-0|pipeline` = **0 trafień**.
- `tools/verify/gates/registry.sh` — odwołuje się do P-079..P-089 (HUMAN-SIMULATION) i P-090..P-098 (SIMULATION) **wyłącznie w polach `description` i `inputs`** gate'ów (linie 484-513). Te gate'y **sprawdzają czy pipeline'y są zarejestrowane w pipelines.sh** — to weryfikacja istnienia, nie wywołanie. Dowód (`tools/verify/gates/domains/human.sh:51-52`):
  ```
  # ── HUM-REG-01: pipeline'y P-079..P-089 zarejestrowane ──────
  # Każdy pipeline z rodziny HUMAN-SIMULATION MUSI być w pipelines.sh
  ```
  To **jednostronna zależność weryfikacyjna** (gate sprawdza pipeline), nie dwukierunkowe połączenie wykonawcze.

### 1.3 Czy jest orchestrator łączący oba?

**Jest JEDNO miejsce delegacji, ale jest OPCJONALNE i NIE jest używane przez hooki/CI.**

`tools/verify/verify.sh` ma subkomendę `pipelines` (linie 194-211), która deleguje do `automation.sh`:
```bash
pipelines)
  # PIPELINE OPERATING SYSTEM — delegacja do tools/automation.
  bash "$ROOT/tools/automation/automation.sh" "${PROFILE:-verify}"
```
oraz subkomendę `gates` (linie 168-192), która uruchamia `enforcement.sh` + `gate-integrity.sh`.

**ALE:** subkomenda `pipelines` NIE jest wywoływana nigdzie w repo (grep `verify\.sh pipelines` = 0 trafień poza samą definicją). Hooki i CI wywołują wyłącznie `verify.sh gates <PROFILE>`.

### 1.4 Wniosek

Jedyny punkt styku to:
1. Opcjonalna, nieużywana subkomenda `verify.sh pipelines` (delegacja GATE→PIPELINE, jednokierunkowa).
2. Opisowe/weryfikacyjne odwołania P-079..P-098 w gate'ach HUMAN/SIMULATION (PIPELINE→GATE sprawdza istnienie).

Nie ma żadnego mechanizmu, który mówi "pipeline P-XXX przechodzi przez gate GATE-YYY" ani "gate GATE-YYY jest częścią pipeline'u P-XXX".

## 2. Entry pointy wykonawcze

| Entry point | Co uruchamia | Profil | Kiedy |
|---|---|---|---|
| `tools/verify/verify.sh` | Repository Certification Engine. Subkomendy: `reconcile` (domyślna), `drift`, `history`, `debt`, `waivers`, `gates`, `config`, `pipelines`. Zawsze najpierw `self-profile-integrity.sh` (meta-gate SELF-001). | `full` (domyślny) | manual / hooki / CI |
| `tools/verify/gates/enforcement.sh` | Egzekwuje gate'y z registry dla profilu. Wywoływany przez `verify.sh gates`. | `LOCAL_FAST` (domyślny), `PRE_PUSH`, `CI`, `RELEASE` | przez `verify.sh gates` |
| `tools/automation/automation.sh` | Pipeline Operating System. Subkomendy: `verify` (domyślna), `audit`, `release`, `deploy`, `certify`, `list`. Uruchamia pipeline'y wg klasy. | klasy FAST/STANDARD/DEEP/RELEASE/CONTINUOUS | manual / `verify.sh pipelines` (nieużywane) |
| `tools/automation/core/pipelines.sh` | Katalog pipeline'ów (P-001..P-098) + funkcje pomocnicze. **Nie jest entry pointem** — źródło danych dla automation.sh. | — | ładowany przez automation.sh |
| `.git-hooks/pre-commit` | Architektura guardrails (sekrety, IP, latest image) + **`verify.sh gates LOCAL_FAST`** | LOCAL_FAST | pre-commit |
| `.git-hooks/pre-push` | Branch policy + **`verify.sh gates PRE_PUSH`** | PRE_PUSH | pre-push |
| `.github/workflows/ci.yml` | validate-sot, architecture-boundaries, unit, **`verify.sh gates CI`** | CI | PR / push main |
| `.github/workflows/release.yml` | **`verify.sh gates RELEASE`** + release | RELEASE | tag v* |
| `.github/workflows/feature.yml` | branch prefix + **`verify.sh gates PRE_PUSH`** | PRE_PUSH | PR |
| `.github/workflows/regression.yml` | **`verify.sh gates PRE_PUSH`** | PRE_PUSH | PR / push main |
| `.github/workflows/security.yml` | secret scan + **`verify.sh gates CI`** | CI | PR / push main / cron |
| `.github/workflows/drift.yml` | **`verify.sh drift`** | — | PR / push main / cron |
| `.github/workflows/helios.yml` | **`verify.sh gates RELEASE`** | RELEASE | PR |
| `.github/workflows/sot.yml` | validate-sot + single-owner SoT | — | PR / push main |
| `tools/automation/monitor/monitor.sh` | Monitor Plane — lifecycle pipeline'ów (register/schedule/queue/start/control/complete/notify/archive) + gate'y MON-* | — | manual |

**Kluczowa obserwacja:** Żaden hook ani workflow CI **nie uruchamia pipeline'ów** (automation.sh). Wszystkie wywołują wyłącznie GATE system (`verify.sh gates`). Pipeline'y są uruchamiane tylko ręcznie przez `automation.sh` lub przez nieużywaną subkomendę `verify.sh pipelines`.

## 3. Graf traceability jest myląco nazwany

`docs/graphs/traceability.mmd` (nazwany "Traceability pipeline → gate → evidence") w rzeczywistości NIE łączy pipeline'ów z gate'ami — zawiera WYŁĄCZNIE:
- `P-XXX -->|executes| skrypt` (pipeline → skrypt)
- `GATE-XXX -->|verified by| GATE-XXX` (gate → sam siebie, tautologia)

**Nie ma ani jednej krawędzi P-XXX → GATE-XXX.** Mimo nazwy, graf nie łączy pipeline'ów z gate'ami.

## 4. Podsumowanie luk połączeniowych

1. **Brak krawędzi pipeline→gate w grafie traceability.**
2. **Brak odwołań krzyżowych w źródłach prawdy.** `pipelines.yaml` nie zna GATE-XXX; `gates.yaml` nie zna P-XXX.
3. **Różne profile/klasy.** Pipeline'y używają klas (FAST/STANDARD/DEEP/RELEASE/CONTINUOUS); gate'y używają profili (LOCAL_FAST/PRE_PUSH/CI/RELEASE). Te taksonomie są **niezmapowane** — nie ma konwersji klasa↔profil.
4. **Różne entry pointy.** Hooki/CI wywołują tylko `verify.sh gates`; pipeline'y uruchamiane tylko ręcznie przez `automation.sh`.
5. **Jedyny most jest jednokierunkowy i nieużywany.** `verify.sh pipelines` deleguje do automation.sh, ale nikt tego nie wywołuje.
6. **Jedyna zależność krzyżowa jest weryfikacyjna.** Gate'y HUMAN/SIMULATION sprawdzają czy pipeline'y P-079..P-098 są zarejestrowane — to kontrola istnienia, nie wykonanie.

## 5. Rekomendacja (do Etapu 2)

Zbudować **jawny most pipeline↔gate**: mapowanie klasa↔profil + deklaratywne powiązanie P-XXX → GATE-YYY w źródłach prawdy + wspólny orchestrator (np. rozszerzenie `verify.sh` o subkomendę `all` uruchamiającą gate'y i pipeline'y w jednym przebiegu) + podpięcie do hooków/CI. Szczegóły w PROD-READY-GAP-ANALYSIS.md.
