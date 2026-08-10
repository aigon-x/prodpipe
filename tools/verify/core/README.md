# tools/verify/core

> Biblioteki współdzielone silnika weryfikacji AIGON Production Platform.

## 1. Purpose
Dostarcza współdzielone funkcje i konfigurację dla wszystkich modułów weryfikacji: liczniki, raportowanie, profile modułów, model reconcile.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla bibliotek weryfikacji.

## 4. Contains
- `lib.sh` — liczniki (VERIFY_FAIL/WARN/INFO/PASS/CHECKS), funkcje pass/fail/warn/info, `verify_module_exit`, `verify_root`, `repo_file`, `repo_dir`, `say()`.
- `profiles.sh` — tablica `VERIFY_MODULES` (git/security/structure/architecture/dependencies/reproducibility/deployment/contracts/migration/recovery z profile:severity).
- `report.sh` — `verify_header`, `verify_module_report`, `verify_block_message`, `verify_success_message`.
- `reconcile.sh` — model 4-warstwowy CANON/DRIFT/HISTORY/DEBT, `recon_begin/cell/end/print_table`, `recon_status`, `recon_baseline_diff`.

## 5. Does Not Contain
Nie zawiera logiki konkretnych modułów weryfikacji ani sekretów.

## 6. Dependencies
Zależy od `bash`, narzędzi standardowych POSIX.

## 7. Consumers
Wszystkie moduły `tools/verify/*` oraz `verify.sh`.

## 8. Synchronization
Klasa: `CANONICAL` — biblioteki są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów — tylko logika weryfikacji.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER`

## 12. Drift Detection
Wykrywanie rozjazdu między bibliotekami (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
