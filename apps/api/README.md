# api

> Katalog aplikacji API AIGON Production Platform — publiczne/wewnętrzne API platformy.

## 1. Purpose
Cel: aplikacja API (serwis HTTP) udostępniająca interfejsy platformy AIGON. Tu żyje kod, kontrakty API, konfiguracja deklaratywna i manifesty aplikacji api.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, kontrakty/schematy API, manifesty). Runtime = actual state (stan wdrożenia, health). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy aplikacji API, kontrakty/schematy API, manifesty wdrożeniowe, konfiguracja deklaratywna, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów (tylko schematy/templates/referencje), brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/runtime`, `system/router`, `system/gateway`, `system/identity`, `system/security`, `system/registry`.

## 7. Consumers
Aplikacje (`apps/*`), klienci zewnętrzni, `system/gateway`, `system/observability`. `STATUS: UNDEFINED` dla pełnej listy.

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
