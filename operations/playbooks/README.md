# playbooks

> Katalog dla playbooków AIGON Production Platform — scenariusze operacyjne i automatyzacja.

## 1. Purpose
Przechowuje playbooki — scenariusze operacyjne i automatyzację powtarzalnych działań.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla playbooków. Runtime odzwierciedla actual state wykonanych scenariuszy.

## 4. Contains
Playbooki, scenariusze operacyjne, automatyzacja działań.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od operations/scripts, operations/runbooks.

## 7. Consumers
Operatorzy, narzędzia operacyjne, orkiestrator.

## 8. Synchronization
Klasa: `CANONICAL` — playbooki są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko scenariusze i referencje.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania playbooków.

## 12. Drift Detection
Wykrywanie rozjazdu między playbookami (git) a faktycznie stosowanymi scenariuszami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
