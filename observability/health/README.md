# health

> Katalog dla definicji health-checków AIGON Production Platform — schematy i konfiguracja kontroli zdrowia.

## 1. Purpose
Przechowuje definicje health-checków — schematy, konfigurację i polityki kontroli zdrowia systemu.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji health-checków. Runtime odzwierciedla actual state zdrowia systemu.

## 4. Contains
Definicje health-checków, schematy, konfiguracja kontroli zdrowia, polityki.

## 5. Does Not Contain
Nie zawiera samych wyników health-checków (te żyją w Runtime), sekretów ani runtime state.

## 6. Dependencies
Zależy od Runtime oraz observability/metrics, observability/alerts.

## 7. Consumers
Narzędzia obserwowalności, orkiestrator, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — definicje health-checków są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i polityki.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania definicji health-checków.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami health-checków (git) a faktycznym stanem zdrowia (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
