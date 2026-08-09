# landing

> Katalog aplikacji landing page AIGON Production Platform — publiczna strona marketingowa/informacyjna.

## 1. Purpose
Cel: publiczna strona landing/marketingowa platformy AIGON. Tu żyje kod, konfiguracja deklaratywna i manifesty aplikacji landing.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, manifesty, konfiguracja deklaratywna). Runtime = actual state (stan wdrożenia, health). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy aplikacji landing, manifesty wdrożeniowe, konfiguracja deklaratywna, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów, brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/gateway`, `system/router`, `system/observability`.

## 7. Consumers
Odwiedzający publiczni, `system/gateway`, `system/observability`. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
`STATUS: UNDEFINED` — klasa synchronizacji nieustalona.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia nieustalony (repo nowe, nic nie zaimplementowane).

## 10. Security
Klasyfikacja danych: publiczna. Zasada: brak sekretów w git, dostęp publiczny ograniczony do warstwy prezentacji.

## 11. Recovery
`STATUS: UNDEFINED` — procedura odzyskiwania nieustalona.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu między desired state (git) a actual state (runtime).

## Examples
`STATUS: UNDEFINED`
