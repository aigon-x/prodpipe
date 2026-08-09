# registry

> Katalog mesh przechowujący artefakty warstwy registry — deklaracje i konfigurację rejestru nodów / usług.

## 1. Purpose
Przechowywanie artefaktów warstwy registry mesh — deklaracji i konfiguracji rejestru nodów / usług.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny mesh nie jest jeszcze przypisany.

## 3. Source of Truth
Git = desired state (deklaracje / konfiguracja), Runtime = actual state (faktyczny rejestr nodów / usług).

## 4. Contains
Artefakty warstwy registry: deklaracje, konfiguracja rejestru nodów / usług.

## 5. Does Not Contain
- Dane runtime'owe (to domena AIGON-X-FS).
- Sekrety (tylko schematy/templates/referencje/polityki rotacji).
- Drugi Source of Truth — registry mesh jest jedynym rejestrem nodów / usług.

## 6. Dependencies
Mesh (katalog nadrzędny), discovery, topology, health.

## 7. Consumers
Runtime, komponenty mesh, warstwa registry. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `CANONICAL` / `REPLICATED`. Rejestr jest kanoniczny i replikowany między nodami. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia artefaktów registry nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja: konfiguracja registry. Zakaz sekretów. Ograniczony dostęp do rejestru.

## 11. Recovery
Odzyskiwanie z Git (desired state) / replik. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie stanu faktycznego (Runtime) ze stanem pożądanym (Git). `STATUS: ARCHITECTURAL GAP` dla mechanizmu.

## Examples
`STATUS: UNDEFINED`.
