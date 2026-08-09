# data

> Katalog mesh przechowujący artefakty warstwy danych (data plane) — deklaracje i konfigurację przepływu danych w mesh'u.

## 1. Purpose
Przechowywanie artefaktów warstwy danych (data plane) mesh — deklaracji i konfiguracji przepływu danych.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny mesh nie jest jeszcze przypisany.

## 3. Source of Truth
Git = desired state (deklaracje / konfiguracja), Runtime = actual state (stan faktyczny przepływu danych).

## 4. Contains
Artefakty warstwy danych: deklaracje, konfiguracja przepływu danych w mesh'u.

## 5. Does Not Contain
- Dane runtime'owe (to domena AIGON-X-FS).
- Sekrety (tylko schematy/templates/referencje/polityki rotacji).
- Drugi Source of Truth.

## 6. Dependencies
Mesh (katalog nadrzędny), warstwa transportu, AIGON-X-FS (dane).

## 7. Consumers
Runtime, komponenty mesh, warstwa danych. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `CANONICAL` / `REPLICATED`. Konfiguracja warstwy danych jest kanoniczna i replikowana. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia artefaktów warstwy danych nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja: konfiguracja warstwy danych. Zakaz sekretów. Granice wg tenantów/użytkowników.

## 11. Recovery
Odzyskiwanie z Git (desired state) / replik. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie stanu faktycznego (Runtime) ze stanem pożądanym (Git). `STATUS: ARCHITECTURAL GAP` dla mechanizmu.

## Examples
`STATUS: UNDEFINED`.
