# observability

> Katalog obserwowalności AIGON Production Platform — monitoring, telemetria, health, alerting.

## 1. Purpose
Przechowuje artefakty obserwowalności: monitoring, telemetria, health, alerting, metryki.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji obserwowalności. Runtime odzwierciedla actual state.

## 4. Contains
Monitoring, telemetria, health, alerting, metryki, schematy health.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od system, config, contracts.

## 7. Consumers
Operatorzy, narzędzia monitoringu, self-heal.

## 8. Synchronization
Klasa: `CANONICAL` — definicje obserwowalności są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko definicje i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania obserwowalności.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami obserwowalności (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
