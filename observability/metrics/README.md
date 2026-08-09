# metrics

> Katalog dla definicji metryk AIGON Production Platform — schematy i konfiguracja metryk.

## 1. Purpose
Przechowuje definicje metryk — schematy, konfigurację i polityki zbierania metryk.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji metryk. Runtime odzwierciedla actual state zebranych metryk.

## 4. Contains
Definicje metryk, schematy, konfiguracja zbierania metryk, polityki.

## 5. Does Not Contain
Nie zawiera samych wartości metryk (te żyją w magazynie metryk), sekretów ani runtime state.

## 6. Dependencies
Zależy od magazynu metryk oraz observability/dashboards, observability/alerts.

## 7. Consumers
Narzędzia obserwowalności, orkiestrator, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — definicje metryk są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i polityki.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania definicji metryk.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami metryk (git) a faktycznie zbieranymi metrykami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
