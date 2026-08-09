# gateway

> Katalog systemu bramy AIGON Production Platform — brama wejściowa do platformy.

## 1. Purpose
Cel: system gateway — brama wejściowa (API gateway / edge) platformy AIGON. Tu żyje kod, konfiguracja deklaratywna i manifesty systemu gateway.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, konfiguracja deklaratywna, reguły bramy). Runtime = actual state (topologia, health, rejestry). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy systemu gateway, reguły bramy (declarative config), konfiguracja deklaratywna, manifesty wdrożeniowe, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów (tylko schematy/templates/referencje), brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/router`, `system/identity`, `system/security`, `system/registry`, `system/observability`.

## 7. Consumers
Klienci zewnętrzni, wszystkie `apps/*`, `system/control-plane`, `system/observability`. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
`STATUS: UNDEFINED` — klasa synchronizacji nieustalona.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia nieustalony (repo nowe, nic nie zaimplementowane).

## 10. Security
Klasyfikacja danych: `STATUS: UNDEFINED`. Zasada: brak sekretów w git, uwierzytelnianie przez `system/identity`, autoryzacja przez `system/security`.

## 11. Recovery
`STATUS: UNDEFINED` — procedura odzyskiwania nieustalona.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu między desired state (git) a actual state (runtime).

## Examples
`STATUS: UNDEFINED`
