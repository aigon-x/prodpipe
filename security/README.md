# security

> Katalog bezpieczeństwa AIGON Production Platform — polityki, audyty, secret-scan, threat model.

## 1. Purpose
Przechowuje artefakty bezpieczeństwa: polityki, procedury audytowe, secret-scan, threat model.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla polityk bezpieczeństwa. Runtime odzwierciedla actual state.

## 4. Contains
Polityki bezpieczeństwa, procedury audytowe, secret-scan, threat model, klasyfikacja danych.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od governance, contracts, config.

## 7. Consumers
Operatorzy, audytorzy, narzędzia bezpieczeństwa, CI/CD.

## 8. Synchronization
Klasa: `CANONICAL` — polityki bezpieczeństwa są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko polityki i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania bezpieczeństwa.

## 12. Drift Detection
Wykrywanie rozjazdu między politykami (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
