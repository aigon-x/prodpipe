# audit

> Katalog dla definicji audytu AIGON Production Platform — schematy i konfiguracja audytu zdarzeń.

## 1. Purpose
Przechowuje definicje audytu — schematy, konfigurację i polityki rejestrowania zdarzeń audytowych.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji audytu. Runtime odzwierciedla actual state zebranych zdarzeń audytowych.

## 4. Contains
Definicje audytu, schematy, konfiguracja rejestrowania zdarzeń audytowych, polityki.

## 5. Does Not Contain
Nie zawiera samych zdarzeń audytowych (te żyją w magazynie audytu), sekretów ani runtime state.

## 6. Dependencies
Zależy od magazynu audytu oraz observability/logs.

## 7. Consumers
Narzędzia audytowe, operatorzy, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — definicje audytu są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i polityki.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania definicji audytu.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami audytu (git) a faktycznie rejestrowanymi zdarzeniami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
