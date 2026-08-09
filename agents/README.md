# agents

> Katalog agentów AIGON Production Platform — definicje agentów, role, konfiguracja.

## 1. Purpose
Przechowuje definicje agentów: role, konfiguracja, modele, uprawnienia.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji agentów. Runtime odzwierciedla actual state.

## 4. Contains
Definicje agentów, role, konfiguracja, modele, uprawnienia.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od models, config, governance.

## 7. Consumers
Runtime, agenci, operatorzy.

## 8. Synchronization
Klasa: `CANONICAL` — definicje agentów są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko definicje i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania definicji agentów.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami agentów (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
