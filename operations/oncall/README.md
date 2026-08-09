# oncall

> Katalog dla konfiguracji oncall AIGON Production Platform — harmonogramy i procedury dyżurów.

## 1. Purpose
Przechowuje konfigurację oncall — harmonogramy dyżurów, procedury eskalacji i role dyżurnych.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla konfiguracji oncall. Runtime odzwierciedla actual state dyżurów.

## 4. Contains
Harmonogramy oncall, procedury eskalacji, role dyżurnych, konfiguracja powiadomień.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od operations/runbooks, operations/incidents, observability/alerts.

## 7. Consumers
Operatorzy, dyżurni, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — konfiguracja oncall jest źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko harmonogramy i procedury.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania konfiguracji oncall.

## 12. Drift Detection
Wykrywanie rozjazdu między konfiguracją oncall (git) a faktycznymi dyżurami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
