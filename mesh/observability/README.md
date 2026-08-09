# observability

> Katalog mesh przechowujący artefakty warstwy obserwowalności — deklaracje i konfigurację monitorowania / metryk / logów / śledzenia.

## 1. Purpose
Przechowywanie artefaktów warstwy obserwowalności mesh — deklaracji i konfiguracji monitorowania, metryk, logów i śledzenia.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny mesh nie jest jeszcze przypisany.

## 3. Source of Truth
Git = desired state (deklaracje / konfiguracja), Runtime = actual state (faktyczne metryki / logi / ślady).

## 4. Contains
Artefakty warstwy obserwowalności: deklaracje, konfiguracja monitorowania / metryk / logów / śledzenia.

## 5. Does Not Contain
- Dane runtime'owe (to domena AIGON-X-FS).
- Sekrety (tylko schematy/templates/referencje/polityki rotacji).
- Drugi Source of Truth.

## 6. Dependencies
Mesh (katalog nadrzędny), health, AIGON-X-FS (dane obserwowalności).

## 7. Consumers
Runtime, komponenty mesh, warstwa obserwowalności. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `CANONICAL` / `REPLICATED`. Konfiguracja obserwowalności jest kanoniczna i replikowana. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia artefaktów obserwowalności nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja: konfiguracja obserwowalności. Zakaz sekretów. Ochrona danych obserwowalności przed nieautoryzowanym dostępem.

## 11. Recovery
Odzyskiwanie z Git (desired state) / replik. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie stanu faktycznego (Runtime) ze stanem pożądanym (Git). `STATUS: ARCHITECTURAL GAP` dla mechanizmu.

## Examples
`STATUS: UNDEFINED`.
