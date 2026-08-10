# ADR-0011 — Observability Baseline (OBS-BASELINE)

> **Type:** ADR
> **Status:** PROPOSED
> **Owner:** UNASSIGNED
> **Supersedes:** —
> **Superseded By:** —
> **Source of Truth:** Git (governance/decisions)

## 1. Title

Observability Baseline (OBS-BASELINE) — wprowadzenie obowiązkowego baseline'u obserwowalności dla projektów rodzonych z szablonu AIGON Production.

## 2. Status

**PROPOSED**

Uzasadnienie: niniejszy dokument jest design doc — definiuje baseline obserwowalności (logowanie, metryki, alerty, health, SLO, dashboardy, syntetyki, deadman) i jego integrację z gate'ami, ale nie jest jeszcze w pełni wdrożony. Status `PROPOSED` sygnalizuje, że decyzja wymaga akceptacji (przegląd architektoniczny) zanim stanie się wiążąca. Przejście do `ACCEPTED` nastąpi po zatwierdzeniu i rozpoczęciu implementacji.

## 3. Context

System Quality Gates (Sekcja 9 w `ARCHITECTURE.md`) definiuje gate'y G0–G8. OBS-BASELINE dodaje warstwę **obserwowalności** — gwarancję, że projekt rodzący się z szablonu jest od pierwszego dnia operacyjny: da się go logować, mierzyć, alarmować i diagnozować.

Zasada P0#1: każdy gate zapisuje wynik do StateStore (tabela `evidence`). Gate bez evidence = FAIL (meta-gate `VERIFY-EVIDENCE-COMPLETE`). OBS-BASELINE rozszerza to o **dane operacyjne** — SLO i alerty trafiają do StateStore (migracja 0009).

**Problem:** świeże projekty rodzą się bez obserwowalności — brak strukturalnego logowania, metryk, alertów, health endpoints, SLO. To prowadzi do "czarnych skrzynek": serwis działa, ale nikt nie wie jak, i nikt nie wie kiedy przestanie działać. OBS-BASELINE rozwiązuje to u źródła — szablon rodzi obserwowalne projekty.

## 4. Problem

Brak baseline'u obserwowalności. Obecnie projekt może przejść certyfikację bez:
- strukturalnego logowania (JSON lines przez `lib/log.sh`),
- metryk RED (Rate/Errors/Duration),
- alertów z runbookiem i ownerem,
- health endpoints (`/healthz`, `/readyz`),
- SLO z alert_ref,
- dashboardów dla krytycznych serwisów,
- syntetyków (dla projektów web),
- deadman switch (heartbeat) dla krytycznych serwisów.

Skutek: projekty są nieoperacyjne — nie da się ich monitorować, alarmować ani diagnozować. OBS-BASELINE definiuje **minimalny próg obserwowalności**, który każdy projekt MUSI spełnić.

## 5. Decision

### 5.1 Zakres OBS-BASELINE

OBS-BASELINE definiuje 16 checków (OBS-01..OBS-16) podzielonych na moduły:

| Moduł | Checki | Zakres |
|---|---|---|
| `obs-logging-check.sh` | OBS-01, OBS-02, OBS-01b | Strukturalne logowanie (JSON przez `lib/log.sh`), scrubbing PII/sektetów |
| `obs-metrics-check.sh` | OBS-03, OBS-06 | Metryki RED, nazewnictwo, kardynalność, kompletność definicji |
| `obs-alerts-check.sh` | OBS-05, OBS-11, OBS-12 | Alerty mają runbook, owner, severity |
| `obs-health-endpoints.sh` | OBS-10 | Health endpoints (`/healthz`, `/readyz`) — warunkowy (web) |
| `obs-deadman-check.sh` | OBS-13 | Deadman switch (heartbeat) dla krytycznych serwisów |
| `obs-slo-check.sh` | OBS-14 | SLO: target w zakresie, alert_ref, floor tier |
| `obs-dashboards-check.sh` | OBS-15 | Dashboardy dla krytycznych serwisów |
| `obs-synthetics-check.sh` | OBS-16 | Syntetyki — warunkowy (web) |

### 5.2 Warunkowość (manifest `.skeleton.yaml`)

Niektóre moduły są **warunkowe** — zależą od cech projektu z `.skeleton.yaml`:

- `web: true` → projekt eksponuje HTTP → `obs-health-endpoints.sh` i `obs-synthetics-check.sh` sprawdzają (OBS-10, OBS-16).
- `web: false` → moduły robią **SKIP + evidence N/A** (projekt nie eksponuje HTTP).
- `tier: 1..3` → klasa krytyczności determinuje **floor**:
  - SLO: tier 1 → target ≥ 0.99, tier 2 → ≥ 0.95, tier 3 → ≥ 0.90 (OBS-14).
  - Deadman: obowiązkowy dla tier 1-2 (OBS-13).
  - Dashboardy: obowiązkowe dla tier 1-2 (OBS-15).

### 5.3 Integracja z gate'ami

Moduły obs-* są rejestrowane w `config/canonical/gates.yaml` (metadata-driven) i uruchamiane przez `verify.sh` w profilach `full`, `release`, `genesis`. `gen-profiles.sh` regeneruje `profiles.sh`.

### 5.4 StateStore (migracja 0009)

Migracja `0009_observability.sql` tworzy tabele `slo` i `alerts` w StateStore. SLO i alerty są częścią canonical state — źródło prawdy w git. `alert_ref` w SLO wskazuje na `alert_id` w `alerts` (korelacja cel→alarm).

### 5.5 Fail-closed

Każdy check OBS-XX jest **fail-closed**: brak manifestu, brak danych, błąd walidacji → FAIL (nie skip). Zgodne z zasadą P0#1 — brak danych/niepewność nie może być traktowana jako sukces. Wyjątek: moduły warunkowe (web:false) robią SKIP + evidence N/A — to świadoma decyzja, nie brak danych.

## 6. Alternatives

| Alternatywa | Odrzucona, bo |
|---|---|
| Brak baseline'u (status quo) | Projekty rodzą się nieoperacyjne — "czarne skrzynki" |
| Tylko logowanie (bez metryk/alertów/SLO) | Logi bez metryk i alertów nie dają pełnej obserwowalności |
| Wszystkie moduły obowiązkowe (bez warunkowości) | Projekty nie-web nie mają health endpoints — fałszywe FAIL-e |
| Tylko dokumentacja (bez checków) | Dokumentacja bez egzekucji to martwy papier — gate'y egzekwują |

## 7. Consequences

**Pozytywne:**
- Projekty rodzą się operacyjne — logowanie, metryki, alerty, health, SLO od pierwszego dnia.
- Alerty mają runbook i owner — nikt nie ignoruje alarmu.
- SLO mają alert_ref — cel bez alarmu to FAIL.
- Warunkowość (web/tier) eliminuje fałszywe FAIL-e dla projektów nie-web.
- Fail-closed gwarantuje, że brak danych nie osłabia bramki jakości.

**Negatywne:**
- Koszt utrzymania manifestów (observability.yaml, slo.yaml, alerts/, dashboards.yaml, synthetics.yaml).
- Ryzyko "placeholderów" — manifesty deklarują, ale realne integracje wymagają pracy.
- Warunkowość dodaje złożoność (czytanie `.skeleton.yaml`).

**Kompromisy:**
- Głębokość vs szerokość: baseline pokrywa szeroko (16 checków), ale płytko (deklaracje, nie żywotność). Realne integracje (Prometheus, Grafana, alertmanager) to osobna warstwa.
- Obowiązkowość vs elastyczność: tier 3 ma niższe progi (SLO 0.90, brak deadman/dashboardów), tier 1-2 wyższe.

## 8. Evidence

- `ARCHITECTURE.md` Sekcja 9, zasada P0#1: każdy gate zapisuje wynik do StateStore.
- `config/canonical/observability.yaml`: manifest metryk (OBS-03, OBS-06), health (OBS-10), deadman (OBS-13).
- `config/canonical/slo.yaml`: manifest SLO (OBS-14).
- `config/canonical/alerts/_template.yaml`: szablon alertów (OBS-05, OBS-11, OBS-12).
- `config/canonical/dashboards.yaml`: rejestr dashboardów (OBS-15).
- `config/canonical/synthetics.yaml`: rejestr syntetyków (OBS-16).
- `.skeleton.yaml`: manifest cech projektu (web/events/tier).
- Migracja `0009_observability.sql`: tabele `slo` i `alerts`.
- `tools/verify/obs-*.sh`: moduły checków OBS-XX.

## 9. Source of Truth

Git — `governance/decisions/ADR-0011-observability-baseline.md`.

## 10. Owner

`UNASSIGNED` (do przypisania w procesie akceptacji).

## 11. Supersedes

—

## 12. Superseded By

—
