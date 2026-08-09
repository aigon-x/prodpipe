# contracts

> Katalog kontraktów AIGON Production Platform — umowy, schematy, interfejsy, SLA.

## 1. Purpose
Przechowuje kontrakty: umowy, schematy, interfejsy, SLA, definicje kontraktowe.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla kontraktów. Runtime odzwierciedla actual state.

## 4. Contains
Kontrakty, schematy, interfejsy, SLA, definicje kontraktowe.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od governance, config, shared.

## 7. Consumers
Wszystkie domeny platformy.

## 8. Synchronization
Klasa: `CANONICAL` — kontrakty są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko kontrakty i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania kontraktów.

## 12. Drift Detection
Wykrywanie rozjazdu między kontraktami (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
