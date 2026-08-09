# identity

> Katalog systemu tożsamości AIGON Production Platform — tożsamość i uwierzytelnianie.

## 1. Purpose
Cel: system identity — tożsamość, uwierzytelnianie i zarządzanie tożsamościami platformy AIGON. Tu żyje kod, konfiguracja deklaratywna i manifesty systemu identity.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, konfiguracja deklaratywna, schematy tożsamości). Runtime = actual state (tożsamości, rejestry, dowody). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy systemu identity, schematy tożsamości, konfiguracja deklaratywna, manifesty wdrożeniowe, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów (tylko schematy/templates/referencje/zasady rotacji), brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/security`, `system/registry`, `system/events`, `system/runtime`.

## 7. Consumers
Wszystkie `apps/*`, `system/gateway`, `system/router`, `system/control-plane`, `system/security`. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
`STATUS: UNDEFINED` — klasa synchronizacji nieustalona.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia nieustalony (repo nowe, nic nie zaimplementowane).

## 10. Security
Klasyfikacja danych: wrażliwa (tożsamości). Zasada: brak sekretów w git, rotacja kluczy przez `system/security`.

## 11. Recovery
`STATUS: UNDEFINED` — procedura odzyskiwania nieustalona.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu między desired state (git) a actual state (runtime).

## Examples
`STATUS: UNDEFINED`
