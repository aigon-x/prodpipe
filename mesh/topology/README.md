# topology

> Katalog mesh przechowujący artefakty warstwy topologii — deklaracje i konfigurację struktury / połączeń mesh.

## 1. Purpose
Przechowywanie artefaktów warstwy topologii mesh — deklaracji i konfiguracji struktury / połączeń między nodami.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny mesh nie jest jeszcze przypisany.

## 3. Source of Truth
Git = desired state (deklaracje / konfiguracja), Runtime = actual state (faktyczna topologia).

## 4. Contains
Artefakty warstwy topologii: deklaracje, konfiguracja struktury / połączeń mesh.

## 5. Does Not Contain
- Dane runtime'owe (to domena AIGON-X-FS).
- Sekrety (tylko schematy/templates/referencje/polityki rotacji).
- Drugi Source of Truth.

## 6. Dependencies
Mesh (katalog nadrzędny), discovery, transport, registry.

## 7. Consumers
Runtime, komponenty mesh, warstwa topologii. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `CANONICAL` / `REPLICATED`. Konfiguracja topologii jest kanoniczna i replikowana. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia artefaktów topologii nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja: konfiguracja topologii. Zakaz sekretów. Ograniczony dostęp do informacji o topologii.

## 11. Recovery
Odzyskiwanie z Git (desired state) / replik. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie stanu faktycznego (Runtime) ze stanem pożądanym (Git). `STATUS: ARCHITECTURAL GAP` dla mechanizmu.

## Examples
`STATUS: UNDEFINED`.
