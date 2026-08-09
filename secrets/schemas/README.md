# schemas

> Katalog schematów sekretów — definicje struktury sekretów, NIGDY same sekrety.

## 1. Purpose
Przechowuje schematy sekretów — definicje struktury, formatu i walidacji sekretów. Zasada: **no secrets in git** — same sekrety NIGDY nie trafiają do tego katalogu.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (schematy). Faktyczne sekrety to actual state (Runtime/Vault/secrets manager).

## 4. Contains
Schematy JSON/YAML sekretów, definicje pól, reguły walidacji.

## 5. Does Not Contain
NIE zawiera samych sekretów, kluczy, haseł, tokenów. Same sekrety żyją w secrets manager (Vault).

## 6. Dependencies
`security/keys`, `secrets/templates`, `secrets/references`.

## 7. Consumers
Zespół bezpieczeństwa, narzędzia walidacji (`tools/validation`), secrets manager.

## 8. Synchronization
`CANONICAL` — schematy są źródłem prawdy w git; same sekrety to `CACHE`/`SESSION` w secrets manager.

## 9. Lifecycle
Schematy powstają przy definiowaniu nowych sekretów, zmieniają się przy zmianach formatów, wycofywane gdy sekret znika.

## 10. Security
Krytyczna wrażliwość — katalog NIE może zawierać samych sekretów. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Schematy odzyskiwane z git. Same sekrety odzyskiwane z secrets manager (backup).

## 12. Drift Detection
Drift wykrywany przez skan: wykrycie sekretu w git (git-secrets, gitleaks).

## Examples
`STATUS: UNDEFINED`
