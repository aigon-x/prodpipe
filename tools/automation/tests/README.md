# tools/automation/tests

> Testy samoweryfikujące Pipeline Operating System AIGON Production Platform.

## 1. Purpose
Weryfikuje poprawność Pipeline Operating System: generatora (pipelines.yaml → pipelines.sh), katalogu pipeline'ów (P-001..P-051), funkcji zapytań, fail-closed (wszystkie IMPLEMENTED mają skrypty) oraz spójności DAG (brak cykli).

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla testów Pipeline Operating System.

## 4. Contains
- `test_pipelines.sh` — 12 testów (T1-T12) weryfikujących generator, katalog, funkcje zapytań, fail-closed i DAG.

## 5. Does Not Contain
Nie zawiera sekretów ani danych runtime.

## 6. Dependencies
Zależy od `bash`, `tools/automation/core/lib.sh`, `tools/automation/core/pipelines.sh`, `config/canonical/pipelines.yaml`.

## 7. Consumers
Proces certyfikacji (OPERATION RECONCILE ZERO), CI/CD, `./tools/verify pipelines`.

## 8. Synchronization
Klasa: `CANONICAL` — testy są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów — tylko testy.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER`

## 12. Drift Detection
Wykrywanie rozjazdu między testami (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
