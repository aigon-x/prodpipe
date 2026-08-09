# discovery

> Katalog mesh przechowujący artefakty warstwy discovery — deklaracje i konfigurację wykrywania nodów / usług.

## 1. Purpose
Przechowywanie artefaktów warstwy discovery mesh — deklaracji i konfiguracji wykrywania nodów / usług.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny mesh nie jest jeszcze przypisany.

## 3. Source of Truth
Git = desired state (deklaracje / konfiguracja), Runtime = actual state (wykryte nody / usługi).

## 4. Contains
Artefakty warstwy discovery: deklaracje, konfiguracja wykrywania nodów / usług.

## 5. Does Not Contain
- Dane runtime'owe (to domena AIGON-X-FS).
- Sekrety (tylko schematy/templates/referencje/polityki rotacji).
- Drugi Source of Truth.

## 6. Dependencies
Mesh (katalog nadrzędny), warstwa transportu, registry.

## 7. Consumers
Runtime, komponenty mesh, warstwa discovery. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `CANONICAL` / `REPLICATED`. Konfiguracja discovery jest kanoniczna i replikowana. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia artefaktów discovery nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja: konfiguracja discovery. Zakaz sekretów. Ograniczony dostęp do informacji o nodach.

## 11. Recovery
Odzyskiwanie z Git (desired state) / replik. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie stanu faktycznego (Runtime) ze stanem pożądanym (Git). `STATUS: ARCHITECTURAL GAP` dla mechanizmu.

## Examples
`STATUS: UNDEFINED`.
