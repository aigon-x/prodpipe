# keys

> Katalog referencji do kluczy — schematy i referencje, NIGDY same klucze.

## 1. Purpose
Przechowuje schematy, szablony i referencje do kluczy kryptograficznych i API. Zasada: **no secrets in git** — same klucze NIGDY nie trafiają do tego katalogu.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (schematy/referencje). Faktyczne klucze to actual state (Runtime/Vault/secrets manager).

## 4. Contains
Schematy kluczy, referencje do lokalizacji kluczy, szablony, polityki rotacji.

## 5. Does Not Contain
NIE zawiera samych kluczy, sekretów, haseł, tokenów. Same klucze żyją w secrets manager (Vault).

## 6. Dependencies
`secrets/schemas`, `secrets/references`, `secrets/rotation`.

## 7. Consumers
Zespół bezpieczeństwa, zespół platformy, narzędzia rotacji.

## 8. Synchronization
`CANONICAL` — schematy i referencje są źródłem prawdy w git; same klucze to `CACHE`/`SESSION` w secrets manager.

## 9. Lifecycle
Schematy powstają przy definiowaniu nowych kluczy, zmieniają się przy zmianach formatów, wycofywane gdy klucz znika.

## 10. Security
Krytyczna wrażliwość — katalog NIE może zawierać samych kluczy. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Schematy odzyskiwane z git. Same klucze odzyskiwane z secrets manager (backup).

## 12. Drift Detection
Drift wykrywany przez skan: wykrycie sekretu w git (git-secrets, gitleaks).

## Examples
`STATUS: UNDEFINED`
