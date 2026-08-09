# control

> Katalog mesh przechowujący artefakty warstwy kontrolnej (control plane) — deklaracje i konfigurację sterowania mesh'em.

## 1. Purpose
Przechowywanie artefaktów warstwy kontrolnej (control plane) mesh — deklaracji i konfiguracji sterowania mesh'em.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny mesh nie jest jeszcze przypisany.

## 3. Source of Truth
Git = desired state (deklaracje / konfiguracja), Runtime = actual state (stan faktyczny). Kontrola steruje stanem pożądanym.

## 4. Contains
Artefakty warstwy kontrolnej: deklaracje, konfiguracja sterowania mesh'em.

## 5. Does Not Contain
- Dane runtime'owe (to domena AIGON-X-FS).
- Sekrety (tylko schematy/templates/referencje/polityki rotacji).
- Drugi Source of Truth.

## 6. Dependencies
Mesh (katalog nadrzędny), warstwa transportu, discovery, security.

## 7. Consumers
Runtime, komponenty mesh, warstwa kontrolna. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `CANONICAL` / `REPLICATED`. Konfiguracja kontroli jest kanoniczna i replikowana do nodów. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia artefaktów kontroli nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja: konfiguracja kontrolna. Zakaz sekretów. Ograniczony dostęp do warstwy kontrolnej.

## 11. Recovery
Odzyskiwanie z Git (desired state) / replik. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie stanu faktycznego (Runtime) ze stanem pożądanym (Git). `STATUS: ARCHITECTURAL GAP` dla mechanizmu.

## Examples
`STATUS: UNDEFINED`.
