# secrets

> Katalog dla schematów i polityk sekretów AIGON Production Platform — NIGDY nie zawiera samych sekretów.

## 1. Purpose
Przechowuje schematy, szablony, referencje i polityki rotacji sekretów. Zasada: **brak sekretów w git** — tylko schematy/templates/referencje/polityki rotacji.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy dla schematów/polityk sekretów. Same sekrety żyją w zewnętrznym magazynie sekretów (Vault), nie w git.

## 4. Contains
Schematy sekretów, szablony, referencje, polityki rotacji, definicje dostępu.

## 5. Does Not Contain
NIE zawiera samych sekretów ani wartości sekretów. Sekrety żyją w zewnętrznym magazynie.

## 6. Dependencies
Zależy od zewnętrznego magazynu sekretów (Vault) oraz deployment/manifests.

## 7. Consumers
Pipeline wdrożeniowy, orkiestrator, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — schematy i polityki sekretów są źródłem prawdy w git; wartości sekretów są synchronizowane z magazynu.

## 9. Lifecycle
Sekrety podlegają rotacji zgodnie z politykami; schematy zmieniają się w git.

## 10. Security
Klasyfikacja danych: SYSTEM. KRYTYCZNE: brak sekretów w git — tylko schematy, szablony, referencje i polityki rotacji.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania sekretów (zależna od magazynu sekretów).

## 12. Drift Detection
Wykrywanie rozjazdu między politykami sekretów (git) a faktycznym stanem magazynu sekretów. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
