# tools/verify/git

> Moduł weryfikacji integralności git AIGON Production Platform.

## 1. Purpose
Weryfikuje integralność repozytorium git: inicjalizację, politykę gałęzi, historię i politykę tagów.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla weryfikacji integralności.

## 4. Contains
- `integrity.sh` — GIT-001..019: integralność repozytorium (git init, worktree, struktura).
- `branches.sh` — GIT-201..203: polityka prefiksów gałęzi (feature/*, fix/*, migration/*, security/*, release/*, worktree/*, worktree-*).
- `history.sh` — GIT-101..108: weryfikacja historii commitów.
- `tags.sh` — GIT-301..303: polityka tagów (prefiksy case-insensitive, np. BASELINE-0.1.0).

## 5. Does Not Contain
Nie zawiera sekretów ani danych runtime.

## 6. Dependencies
Zależy od `bash`, `git`, `tools/verify/core/lib.sh`.

## 7. Consumers
`verify.sh`, proces certyfikacji (OPERATION RECONCILE ZERO).

## 8. Synchronization
Klasa: `CANONICAL` — moduły git są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów — tylko weryfikacja git.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER`

## 12. Drift Detection
Wykrywanie rozjazdu między stanem git (desired) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
