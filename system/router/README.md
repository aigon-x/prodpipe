# router

> Katalog systemu routera AIGON Production Platform — kierowanie ruchu i żądań w platformie.

## 1. Purpose
Cel: system router — kierowanie ruchu/żądań między komponentami platformy AIGON. Tu żyje kod, konfiguracja deklaratywna i manifesty systemu router.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, konfiguracja deklaratywna, reguły routingu). Runtime = actual state (topologia, health, rejestry). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy systemu router, reguły routingu (declarative config), konfiguracja deklaratywna, manifesty wdrożeniowe, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów, brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/runtime`, `system/gateway`, `system/registry`, `system/identity`, `system/security`.

## 7. Consumers
Wszystkie `apps/*`, `system/gateway`, `system/control-plane`, `system/observability`. `STATUS: UNDEFINED` dla pełnej listy.

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
