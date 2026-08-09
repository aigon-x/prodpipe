# traces

> Katalog dla definicji śladów (traces) AIGON Production Platform — schematy i konfiguracja śledzenia rozproszonego.

## 1. Purpose
Przechowuje definicje śladów — schematy, konfigurację i polityki śledzenia rozproszonego (distributed tracing).

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji śladów. Runtime odzwierciedla actual state zebranych śladów.

## 4. Contains
Definicje śladów, schematy, konfiguracja śledzenia, polityki.

## 5. Does Not Contain
Nie zawiera samych śladów (te żyją w magazynie śladów), sekretów ani runtime state.

## 6. Dependencies
Zależy od magazynu śladów oraz observability/dashboards, observability/alerts.

## 7. Consumers
Narzędzia obserwowalności, orkiestrator, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — definicje śladów są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i polityki.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania definicji śladów.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami śladów (git) a faktycznie zbieranymi śladami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
