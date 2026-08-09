# models

> Katalog modeli AIGON Production Platform — definicje modeli, konfiguracja, routing.

## 1. Purpose
Przechowuje definicje modeli: konfiguracja, routing, uprawnienia, dostępność.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji modeli. Runtime odzwierciedla actual state.

## 4. Contains
Definicje modeli, konfiguracja, routing, uprawnienia, dostępność.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od agents, config, governance.

## 7. Consumers
Runtime, agenci, operatorzy.

## 8. Synchronization
Klasa: `CANONICAL` — definicje modeli są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko definicje i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania definicji modeli.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami modeli (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
