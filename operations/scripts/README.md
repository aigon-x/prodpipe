# scripts

> Katalog dla skryptów operacyjnych AIGON Production Platform — automatyzacja działań operacyjnych.

## 1. Purpose
Przechowuje skrypty operacyjne — automatyzację działań operacyjnych i utrzymaniowych.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla skryptów. Runtime odzwierciedla actual state wykonania.

## 4. Contains
Skrypty operacyjne, automatyzacja działań, narzędzia pomocnicze.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od operations/playbooks, operations/runbooks.

## 7. Consumers
Operatorzy, narzędzia operacyjne, orkiestrator.

## 8. Synchronization
Klasa: `CANONICAL` — skrypty są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypty i referencje.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania skryptów.

## 12. Drift Detection
Wykrywanie rozjazdu między skryptami (git) a faktycznie używanymi wersjami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
