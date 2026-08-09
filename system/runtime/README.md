# runtime

> Katalog systemu runtime AIGON Production Platform — rdzeń wykonawczy platformy.

## 1. Purpose
Cel: system runtime — rdzeń wykonawczy platformy AIGON. Tu żyje kod, kontrakty, konfiguracja deklaratywna i manifesty systemu runtime.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, kontrakty, konfiguracja deklaratywna). Runtime = actual state (stan wykonania, health, topologia, rejestry, dowody, tożsamość noda). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy systemu runtime, kontrakty, konfiguracja deklaratywna, manifesty wdrożeniowe, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów (tylko schematy/templates/referencje), brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/router`, `system/registry`, `system/identity`, `system/events`, `system/security`, `system/health`.

## 7. Consumers
Wszystkie `apps/*`, `system/control-plane`, `system/observability`, `system/self-heal`. `STATUS: UNDEFINED` dla pełnej listy.

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
