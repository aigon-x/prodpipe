# data

> Katalog danych AIGON Production Platform — definicje danych, schematy, trwałe dane.

## 1. Purpose
Przechowuje definicje danych: schematy, trwałe dane, wiedza, pamięć.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji danych. AIGON-X-FS odzwierciedla actual state.

## 4. Contains
Definicje danych, schematy, trwałe dane, wiedza, pamięć.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od filesystem, config, contracts.

## 7. Consumers
Runtime, AIGON-X-FS, operatorzy.

## 8. Synchronization
Klasa: `CANONICAL` — definicje danych są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko definicje i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania definicji danych.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami danych (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
