# security

> Katalog systemu bezpieczeństwa AIGON Production Platform — autoryzacja, polityki i bezpieczeństwo.

## 1. Purpose
Cel: system security — autoryzacja, polityki bezpieczeństwa i ochrona platformy AIGON. Tu żyje kod, polityki (policies-as-code), konfiguracja deklaratywna i manifesty systemu security.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, polityki jako kod, konfiguracja deklaratywna). Runtime = actual state (rejestry, dowody, health). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy systemu security, polityki (policies-as-code), konfiguracja deklaratywna, manifesty wdrożeniowe, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów (tylko schematy/templates/referencje/zasady rotacji), brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/identity`, `system/runtime`, `system/registry`, `system/events`.

## 7. Consumers
Wszystkie `apps/*`, wszystkie `system/*`, `system/control-plane`, `system/observability`. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
`STATUS: UNDEFINED` — klasa synchronizacji nieustalona.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia nieustalony (repo nowe, nic nie zaimplementowane).

## 10. Security
Klasyfikacja danych: wrażliwa (polityki bezpieczeństwa). Zasada: brak sekretów w git, rotacja kluczy, autoryzacja przez `system/identity`.

## 11. Recovery
`STATUS: UNDEFINED` — procedura odzyskiwania nieustalona.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu między desired state (git) a actual state (runtime).

## Examples
`STATUS: UNDEFINED`
