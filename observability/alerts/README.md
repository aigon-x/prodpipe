# alerts

> Katalog dla definicji alertów AIGON Production Platform — polityki i konfiguracja alertowania.

## 1. Purpose
Przechowuje definicje alertów — polityki, reguły i konfigurację alertowania.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji alertów. Runtime odzwierciedla actual state wyzwolonych alertów.

## 4. Contains
Definicje alertów, reguły, polityki alertowania, konfiguracja powiadomień.

## 5. Does Not Contain
Nie zawiera samych wyzwolonych alertów, sekretów ani runtime state.

## 6. Dependencies
Zależy od observability/metrics, observability/logs, observability/traces.

## 7. Consumers
Narzędzia obserwowalności, operatorzy, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — definicje alertów są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i polityki.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania definicji alertów.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami alertów (git) a faktycznie skonfigurowanymi alertami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
