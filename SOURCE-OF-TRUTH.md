# SOURCE-OF-TRUTH — AIGON Production Platform

> Definicja źródeł prawdy. Zasada nadrzędna: **Git = desired state, Runtime = actual state**.
> **STATUS: UNDEFINED** — ramy zdefiniowane; szczegóły w toku.

## Zasada nadrzędna

**Git mówi, co zbudowaliśmy. Runtime mówi, co naprawdę istnieje.**

- **Git** = code / contracts / schemas / declarative config / deployment / tests / policies-as-code / docs / manifests / source artifacts.
- **Runtime** = actual state / discovery / topology / health / tick / registries / evidence / capabilities / node identity / deployment state.

**Reconciliation**: Git (desired) VS Runtime (actual) → **PASS / DRIFT**.

## Single-owner Source of Truth

Każda domena ma **dokładnie jedno** źródło prawdy. Zasada: **no second SoT / registry / memory**.

- Nie tworzymy drugiego registry.
- Nie tworzymy drugiej pamięci.
- Nie tworzymy drugiego SoT.

## Co jest SoT w Git

| Kategoria | SoT |
|---|---|
| Kod | `system/`, `filesystem/`, `mesh/`, `agents/`, `models/`, `apps/`, `business/` |
| Konfiguracja | `config/canonical/` (jedyny SoT konfiguracji) |
| Kontrakty | `contracts/` |
| Deployment | `deployment/` |
| Polityki | `governance/policies/`, `security/policies/` |
| Testy | `tests/` |
| Dokumentacja | `docs/` |

## Co jest SoT w Runtime

| Kategoria | SoT |
|---|---|
| Stan faktyczny | Runtime (actual state) |
| Discovery / topologia | Runtime |
| Health / tick | Runtime |
| Rejestry | Runtime |
| Evidence / capability | Runtime |
| Tożsamość nodów | Runtime |
| Stan deploymentu | Runtime |

## Synchronizacja

Klasy: **CANONICAL / REPLICATED / GENERATED / CACHE / SESSION / EPHEMERAL**.

`shared/` = kanoniczna materializacja + replikacja + płaszczyzna sync. **NIE jest drugim SoT.**

## Walidacja (validate-sot)

Skrypt `.git-hooks/validate-sot` sprawdza:

- brak duplikatów SoT (każda domena ma jednego właściciela)
- brak hardcoded node count / IP / hostname w canonical config
- brak sekretów
- brak nieoznaczonych danych (brak klasy synchronizacji)
- brak `:latest` image w produkcji

## Status

**STATUS: UNDEFINED** — ramy zdefiniowane; pełna macierz SoT w toku.
