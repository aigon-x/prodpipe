# filesystem

> Katalog filesystem AIGON Production Platform — definicje AIGON-X-FS, struktura, dane.

## 1. Purpose
Przechowuje definicje AIGON-X-FS: struktura, dane, trwałe dane runtime.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji filesystem. AIGON-X-FS odzwierciedla actual state.

## 4. Contains
Definicje AIGON-X-FS, struktura, trwałe dane runtime, wiedza, pamięć.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od system, config, contracts.

## 7. Consumers
Runtime, AIGON-X-FS, operatorzy.

## 8. Synchronization
Klasa: `CANONICAL` — definicje filesystem są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko definicje i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania definicji filesystem.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami filesystem (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
