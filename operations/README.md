# operations

> Katalog operacyjny AIGON Production Platform — playbooki, runbooki, backup, restore, chaos.

## 1. Purpose
Przechowuje artefakty operacyjne: playbooki, runbooki, procedury backup/restore, scenariusze chaos.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji operacyjnych. Runtime odzwierciedla actual state.

## 4. Contains
Playbooki, runbooki, procedury backup/restore, scenariusze chaos, automatyzacja operacyjna.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od governance, security, config, deployment.

## 7. Consumers
Operatorzy, narzędzia operacyjne, orkiestrator, self-heal.

## 8. Synchronization
Klasa: `CANONICAL` — definicje operacyjne są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko procedury i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania w operations/restore.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami operacyjnymi (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
