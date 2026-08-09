# runbooks

> Katalog dla runbooków AIGON Production Platform — procedury reagowania na znane zdarzenia.

## 1. Purpose
Przechowuje runbooki — procedury reagowania na znane zdarzenia i awarie.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla runbooków. Runtime odzwierciedla actual state wykonanych procedur.

## 4. Contains
Runbooki, procedury reagowania, instrukcje operacyjne.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od operations/incidents, operations/oncall, observability/alerts.

## 7. Consumers
Operatorzy, oncall, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — runbooki są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko procedury i referencje.

## 11. Recovery
Runbooki definiują procedury odzyskiwania po awariach.

## 12. Drift Detection
Wykrywanie rozjazdu między runbookami (git) a faktycznie stosowanymi procedurami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
