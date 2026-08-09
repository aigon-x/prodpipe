# dashboards

> Katalog dla definicji dashboardów AIGON Production Platform — konfiguracja wizualizacji obserwowalności.

## 1. Purpose
Przechowuje definicje dashboardów — konfigurację wizualizacji metryk, logów i śladów.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji dashboardów. Runtime odzwierciedla actual state wyświetlanych danych.

## 4. Contains
Definicje dashboardów, konfiguracja wizualizacji, panele.

## 5. Does Not Contain
Nie zawiera samych danych obserwowalności, sekretów ani runtime state.

## 6. Dependencies
Zależy od observability/metrics, observability/logs, observability/traces.

## 7. Consumers
Narzędzia obserwowalności, operatorzy, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — definicje dashboardów są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i polityki.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania definicji dashboardów.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami dashboardów (git) a faktycznie wyświetlanymi dashboardami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
