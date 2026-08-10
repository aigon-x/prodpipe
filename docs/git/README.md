# docs/git

> Katalog polityk git AIGON Production Platform — branch, commit, tagging, large files, source vs generated, granica git/runtime.

## 1. Purpose
Przechowuje polityki i procedury zarządzania repozytorium git: branch policy, commit policy, tagging policy, obsługa dużych plików, rozróżnienie source vs generated, oraz granicę między git (desired state) a runtime (actual state).

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla polityk git. Runtime odzwierciedla actual state.

## 4. Contains
- `BRANCH-POLICY.md` — polityka gałęzi
- `COMMIT-POLICY.md` — polityka commitów
- `TAGGING-POLICY.md` — polityka tagów
- `LARGE-FILES.md` — obsługa dużych plików
- `SOURCE-VS-GENERATED.md` — rozróżnienie source vs generated
- `GIT-RUNTIME-BOUNDARY.md` — granica git/runtime

## 5. Does Not Contain
Nie zawiera sekretów, kluczy ani runtime state.

## 6. Dependencies
Zależy od governance, contracts, config.

## 7. Consumers
Operatorzy, architekci, deweloperzy, CI/CD.

## 8. Synchronization
Klasa: `CANONICAL` — polityki git są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko polityki i procedury.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania polityk git.

## 12. Drift Detection
Wykrywanie rozjazdu między politykami git (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
