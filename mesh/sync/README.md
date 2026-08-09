# sync

> Katalog mesh przechowujący artefakty warstwy synchronizacji — deklaracje i konfigurację synchronizacji między nodami.

## 1. Purpose
Przechowywanie artefaktów warstwy synchronizacji mesh — deklaracji i konfiguracji synchronizacji między nodami.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny mesh nie jest jeszcze przypisany.

## 3. Source of Truth
Git = desired state (deklaracje / konfiguracja), Runtime = actual state (stan synchronizacji).

## 4. Contains
Artefakty warstwy synchronizacji: deklaracje, konfiguracja synchronizacji między nodami.

## 5. Does Not Contain
- Dane runtime'owe (to domena AIGON-X-FS).
- Sekrety (tylko schematy/templates/referencje/polityki rotacji).
- Drugi Source of Truth.

## 6. Dependencies
Mesh (katalog nadrzędny), transport, registry, AIGON-X-FS (dane do synchronizacji).

## 7. Consumers
Runtime, komponenty mesh, warstwa synchronizacji. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `CANONICAL` / `REPLICATED`. Konfiguracja synchronizacji jest kanoniczna i replikowana. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia artefaktów synchronizacji nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja: konfiguracja synchronizacji. Zakaz sekretów. Wymagane bezpieczeństwo przesyłanych danych.

## 11. Recovery
Odzyskiwanie z Git (desired state) / replik. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie stanu faktycznego (Runtime) ze stanem pożądanym (Git). `STATUS: ARCHITECTURAL GAP` dla mechanizmu.

## Examples
`STATUS: UNDEFINED`.
