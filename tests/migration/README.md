# migration

> Testy migracji — weryfikują migracje schematu StateStore.

## 1. Purpose
Weryfikuje poprawność migracji schematu StateStore, w tym zgodność wersji schematu i bezpieczeństwo przejść między wersjami.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji migracji schematu.

## 4. Contains
Skrypt `migration.test.sh` oraz przypadki testowe migracji schematu.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od StateStore oraz mechanizmów migracji schematu.

## 7. Consumers
CI/CD, deweloperzy, operatorzy zarządzający migracjami.

## 8. Synchronization
Klasa: `CANONICAL` — skrypt testowy jest źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypt testowy i referencje.

## 11. Recovery
`STATUS: UNDEFINED` — procedury odzyskiwania po nieudanej migracji.

## 12. Drift Detection
Wykrywanie rozjazdu między definicją migracji (git) a faktycznym stanem schematu.
