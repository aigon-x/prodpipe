# console

> Katalog aplikacji konsoli operacyjnej AIGON Production Platform — interfejs zarządzania platformą.

## 1. Purpose
Cel: aplikacja konsoli operacyjnej (web/desktop) do zarządzania platformą AIGON. Tu żyje kod, konfiguracja deklaratywna i manifesty aplikacji konsoli.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, manifesty, konfiguracja deklaratywna). Runtime = actual state (stan wdrożenia, health, topologia). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy aplikacji konsoli, manifesty wdrożeniowe, konfiguracja deklaratywna, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów (tylko schematy/templates/referencje), brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/runtime`, `system/router`, `system/gateway`, `system/control-plane`, `system/observability`.

## 7. Consumers
Operatorzy platformy, `system/control-plane`, `system/observability`. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
`STATUS: UNDEFINED` — klasa synchronizacji nieustalona.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia nieustalony (repo nowe, nic nie zaimplementowane).

## 10. Security
Klasyfikacja danych: `STATUS: UNDEFINED`. Zasada: brak sekretów w git, dostęp kontrolowany przez `system/identity` i `system/security`.

## 11. Recovery
`STATUS: UNDEFINED` — procedura odzyskiwania nieustalona.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu między desired state (git) a actual state (runtime).

## Examples
`STATUS: UNDEFINED`
