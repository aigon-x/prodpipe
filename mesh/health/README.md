# health

> Katalog mesh przechowujący artefakty warstwy health — deklaracje i konfigurację monitorowania zdrowia nodów / usług.

## 1. Purpose
Przechowywanie artefaktów warstwy health mesh — deklaracji i konfiguracji monitorowania zdrowia nodów / usług.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny mesh nie jest jeszcze przypisany.

## 3. Source of Truth
Git = desired state (deklaracje / konfiguracja), Runtime = actual state (faktyczny stan zdrowia).

## 4. Contains
Artefakty warstwy health: deklaracje, konfiguracja monitorowania zdrowia.

## 5. Does Not Contain
- Dane runtime'owe (to domena AIGON-X-FS).
- Sekrety (tylko schematy/templates/referencje/polityki rotacji).
- Drugi Source of Truth.

## 6. Dependencies
Mesh (katalog nadrzędny), observability, registry.

## 7. Consumers
Runtime, komponenty mesh, warstwa health. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `CANONICAL` / `REPLICATED`. Konfiguracja health jest kanoniczna i replikowana. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia artefaktów health nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja: konfiguracja health. Zakaz sekretów. Ograniczony dostęp do informacji o zdrowiu.

## 11. Recovery
Odzyskiwanie z Git (desired state) / replik. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie stanu faktycznego (Runtime) ze stanem pożądanym (Git). `STATUS: ARCHITECTURAL GAP` dla mechanizmu.

## Examples
`STATUS: UNDEFINED`.
