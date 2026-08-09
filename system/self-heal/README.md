# self-heal

> Katalog systemu samonaprawy AIGON Production Platform — automatyczne naprawianie awarii.

## 1. Purpose
Cel: system self-heal — automatyczne wykrywanie i naprawianie awarii platformy AIGON. Tu żyje kod, polityki naprawcze, konfiguracja deklaratywna i manifesty systemu self-heal.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, polityki naprawcze, konfiguracja deklaratywna). Runtime = actual state (health, rejestry, dowody). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy systemu self-heal, polityki naprawcze (policies-as-code), konfiguracja deklaratywna, manifesty wdrożeniowe, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów, brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/health`, `system/telemetry`, `system/events`, `system/runtime`, `system/security`.

## 7. Consumers
`system/control-plane`, `system/observability`, `system/chaos`. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
`STATUS: UNDEFINED` — klasa synchronizacji nieustalona.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia nieustalony (repo nowe, nic nie zaimplementowane).

## 10. Security
Klasyfikacja danych: `STATUS: UNDEFINED`. Zasada: brak sekretów w git, tożsamość przez `system/identity`, autoryzacja przez `system/security`.

## 11. Recovery
`STATUS: UNDEFINED` — procedura odzyskiwania nieustalona.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu między desired state (git) a actual state (runtime).

## Examples
`STATUS: UNDEFINED`
