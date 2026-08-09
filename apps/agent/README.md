# agent

> Katalog aplikacji agenta AIGON Production Platform — aplikacja agenta AI działająca na platformie.

## 1. Purpose
Cel: aplikacja agenta AI (runtime agenta) działająca na platformie AIGON. Tu żyje kod, konfiguracja deklaratywna i manifesty aplikacji agent.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, manifesty, konfiguracja deklaratywna). Runtime = actual state (stan wdrożenia, health, tożsamość noda). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy aplikacji agent, manifesty wdrożeniowe, konfiguracja deklaratywna, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów, brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/runtime`, `system/router`, `system/registry`, `system/identity`, `system/events`, `system/security`.

## 7. Consumers
`system/runtime`, `system/registry`, `system/control-plane`, `system/observability`. `STATUS: UNDEFINED` dla pełnej listy.

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
