# security

> Katalog mesh przechowujący artefakty warstwy bezpieczeństwa — deklaracje i konfigurację zabezpieczeń mesh.

## 1. Purpose
Przechowywanie artefaktów warstwy bezpieczeństwa mesh — deklaracji i konfiguracji zabezpieczeń (authn/authz, szyfrowanie, polityki).

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny mesh nie jest jeszcze przypisany.

## 3. Source of Truth
Git = desired state (deklaracje / polityki), Runtime = actual state (stan zabezpieczeń).

## 4. Contains
Artefakty warstwy bezpieczeństwa: deklaracje, konfiguracja zabezpieczeń, polityki (policies-as-code).

## 5. Does Not Contain
- Dane runtime'owe (to domena AIGON-X-FS).
- Sekrety (tylko schematy/templates/referencje/polityki rotacji — NIGDY samych sekretów).
- Drugi Source of Truth.

## 6. Dependencies
Mesh (katalog nadrzędny), transport (szyfrowanie), registry.

## 7. Consumers
Runtime, komponenty mesh, warstwa bezpieczeństwa. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `CANONICAL` / `REPLICATED`. Polityki bezpieczeństwa są kanoniczne i replikowane. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia artefaktów bezpieczeństwa nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja: konfiguracja bezpieczeństwa. Zakaz sekretów w git. Wymagana rotacja sekretów (polityki rotacji).

## 11. Recovery
Odzyskiwanie z Git (desired state) / replik. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie stanu faktycznego (Runtime) ze stanem pożądanym (Git). `STATUS: ARCHITECTURAL GAP` dla mechanizmu.

## Examples
`STATUS: UNDEFINED`.
