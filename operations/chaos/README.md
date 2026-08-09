# chaos

> Katalog dla testów chaosu AIGON Production Platform — scenariusze i procedury testów odporności.

## 1. Purpose
Przechowuje scenariusze i procedury testów chaosu — weryfikacja odporności systemu na awarie.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla scenariuszy chaosu. Runtime odzwierciedla actual state wykonanych testów.

## 4. Contains
Scenariusze chaosu, procedury testów odporności, konfiguracja eksperymentów.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od operations/runbooks, observability/metrics, observability/alerts.

## 7. Consumers
Operatorzy, narzędzia operacyjne, orkiestrator.

## 8. Synchronization
Klasa: `CANONICAL` — scenariusze chaosu są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko scenariusze i procedury.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania scenariuszy chaosu.

## 12. Drift Detection
Wykrywanie rozjazdu między scenariuszami chaosu (git) a faktycznie wykonanymi testami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
