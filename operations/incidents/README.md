# incidents

> Katalog dla rejestru incydentów AIGON Production Platform — dokumentacja zdarzeń i awarii.

## 1. Purpose
Przechowuje rejestr incydentów — dokumentację zdarzeń, awarii i ich rozwiązań.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla dokumentacji incydentów. Runtime odzwierciedla actual state zdarzeń.

## 4. Contains
Rejestr incydentów, raporty post-mortem, dokumentacja zdarzeń.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od operations/runbooks, operations/oncall, observability/alerts.

## 7. Consumers
Operatorzy, oncall, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — rejestr incydentów jest źródłem prawdy w git.

## 9. Lifecycle
Incydenty są rejestrowane, analizowane i archiwizowane.

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko dokumentacja i referencje.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania rejestru incydentów.

## 12. Drift Detection
Wykrywanie rozjazdu między rejestrem incydentów (git) a faktycznymi zdarzeniami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
