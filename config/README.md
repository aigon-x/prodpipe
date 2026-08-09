# config

> Katalog konfiguracyjny AIGON Production Platform — deklaratywna konfiguracja, schematy.

## 1. Purpose
Przechowuje deklaratywną konfigurację platformy: schematy, szablony, definicje konfiguracyjne.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla konfiguracji deklaratywnej. Runtime odzwierciedla actual state.

## 4. Contains
Deklaratywna konfiguracja, schematy, szablony, definicje konfiguracyjne.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od contracts, governance, deployment.

## 7. Consumers
Runtime, narzędzia wdrożeniowe, operatorzy.

## 8. Synchronization
Klasa: `CANONICAL` — konfiguracja deklaratywna jest źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania konfiguracji.

## 12. Drift Detection
Wykrywanie rozjazdu między konfiguracją (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
