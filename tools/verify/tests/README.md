# tools/verify/tests

> Testy samoweryfikujące silnika weryfikacji AIGON Production Platform (R7 SELF-TESTING).

## 1. Purpose
Weryfikuje poprawność samego silnika weryfikacji: propagację kodów wyjścia, wykrywanie FALSE GATE, regresje EXCLUDE, polityki git/structure, oraz test ROLLBACK.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla testów silnika weryfikacji.

## 4. Contains
- `test_verify.sh` — 10 testów negatywnych + test ROLLBACK (T1-T11).

## 5. Does Not Contain
Nie zawiera sekretów ani danych runtime.

## 6. Dependencies
Zależy od `bash`, `tools/verify/core/lib.sh`, modułów `tools/verify/*`.

## 7. Consumers
Proces certyfikacji (OPERATION RECONCILE ZERO), CI/CD.

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
