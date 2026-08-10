# tools/verify

> Silnik weryfikacji repozytorium AIGON Production Platform — "Jedno wejście, wiele wyspecjalizowanych świadków".

## 1. Purpose
Weryfikuje integralność, spójność i zgodność repozytorium z kontraktami (README, git, security, debt, drift, history, reconcile). Centralny punkt wejścia: `verify.sh`.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state). Moduły weryfikują actual state względem kontraktów zdefiniowanych w repo.

## 4. Contains
- `verify.sh` — główny entry point (subkomendy: `reconcile`, moduły).
- `core/` — biblioteki współdzielone (lib.sh, profiles.sh, report.sh, reconcile.sh).
- `git/` — weryfikacja integralności git (integrity, branches, history, tags).
- `security/` — weryfikacja sekretów i poświadczeń (secrets, credentials, history).
- `structure/` — weryfikacja kontraktów README (readme.sh).
- `debt/` — skaner długu technicznego (scanner.sh, debt.sh).
- `drift/` — wykrywanie rozjazdu (drift.sh).
- `history/` — weryfikacja historii (history.sh).
- `reconcile/` — model 4-warstwowy CANON/DRIFT/HISTORY/DEBT (baseline.sh, reconcile.sh).

## 5. Does Not Contain
Nie zawiera sekretów, danych runtime ani artefaktów generowanych.

## 6. Dependencies
Zależy od `bash`, `git`, `python3` (walidacja JSON), narzędzi standardowych POSIX.

## 7. Consumers
Operatorzy, CI/CD, proces certyfikacji (OPERATION RECONCILE ZERO), procesy wdrożeniowe.

## 8. Synchronization
Klasa: `CANONICAL` — moduły weryfikacji są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Moduły security skanują sekrety; same nie przechowują sekretów.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania silnika weryfikacji.

## 12. Drift Detection
Moduł `drift/` wykrywa rozjazd między desired state (git) a actual state (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
