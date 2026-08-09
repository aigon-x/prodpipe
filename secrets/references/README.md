# references

> Katalog referencji do sekretów — wskaźniki do lokalizacji sekretów, NIGDY same sekrety.

## 1. Purpose
Przechowuje referencje do sekretów — wskaźniki do lokalizacji sekretów w secrets manager, bez samych wartości. Zasada: **no secrets in git** — same sekrety NIGDY nie trafiają do tego katalogu.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (referencje). Faktyczne sekrety to actual state (Runtime/Vault/secrets manager).

## 4. Contains
Referencje do sekretów (ścieżki w Vault, identyfikatory), mapowania nazw na lokalizacje.

## 5. Does Not Contain
NIE zawiera samych sekretów, kluczy, haseł, tokenów. Same sekrety żyją w secrets manager (Vault).

## 6. Dependencies
`secrets/schemas`, `secrets/templates`, `security/keys`.

## 7. Consumers
Zespół bezpieczeństwa, zespół platformy, narzędzia automatyzacji (`tools/automation`).

## 8. Synchronization
`CANONICAL` — referencje są źródłem prawdy w git; same sekrety to `CACHE`/`SESSION` w secrets manager.

## 9. Lifecycle
Referencje powstają przy definiowaniu nowych sekretów, zmieniają się przy zmianach lokalizacji, wycofywane gdy sekret znika.

## 10. Security
Krytyczna wrażliwość — katalog NIE może zawierać samych sekretów. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Referencje odzyskiwane z git. Same sekrety odzyskiwane z secrets manager (backup).

## 12. Drift Detection
Drift wykrywany przez skan: wykrycie sekretu w git (git-secrets, gitleaks).

## Examples
`STATUS: UNDEFINED`
