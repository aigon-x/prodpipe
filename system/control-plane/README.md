# control-plane

> Katalog systemu płaszczyzny kontroli AIGON Production Platform — zarządzanie i sterowanie platformą.

## 1. Purpose
Cel: system control-plane — płaszczyzna kontroli (zarządzanie, sterowanie, orkiestracja) platformy AIGON. Tu żyje kod, konfiguracja deklaratywna i manifesty systemu control-plane.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, konfiguracja deklaratywna, polityki). Runtime = actual state (rejestry, health, dowody, topologia). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy systemu control-plane, konfiguracja deklaratywna, polityki, manifesty wdrożeniowe, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów (tylko schematy/templates/referencje), brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: wszystkie `system/*`, wszystkie `apps/*`, `system/registry`, `system/observability`.

## 7. Consumers
Operatorzy platformy, `apps/console`, `apps/cli`, `system/self-heal`. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
`STATUS: UNDEFINED` — klasa synchronizacji nieustalona.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia nieustalony (repo nowe, nic nie zaimplementowane).

## 10. Security
Klasyfikacja danych: wrażliwa (sterowanie platformą). Zasada: brak sekretów w git, tożsamość przez `system/identity`, autoryzacja przez `system/security`.

## 11. Recovery
`STATUS: UNDEFINED` — procedura odzyskiwania nieustalona.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu między desired state (git) a actual state (runtime).

## Examples
`STATUS: UNDEFINED`
