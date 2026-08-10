# tools/verify/reconcile

> Moduł reconcile AIGON Production Platform — model 4-warstwowy CANON/DRIFT/HISTORY/DEBT.

## 1. Purpose
Implementuje model reconcile 4-warstwowy (CANON/DRIFT/HISTORY/DEBT) oraz baseline do porównywania stanu repozytorium.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla modelu reconcile.

## 4. Contains
- `baseline.sh` — generowanie i porównywanie baseline (tag BASELINE-0.1.0).
- `reconcile.sh` — model 4-warstwowy CANON/DRIFT/HISTORY/DEBT.

## 5. Does Not Contain
Nie zawiera sekretów ani danych runtime.

## 6. Dependencies
Zależy od `bash`, `tools/verify/core/lib.sh`, `tools/verify/core/reconcile.sh`.

## 7. Consumers
`verify.sh reconcile`, proces certyfikacji (OPERATION RECONCILE ZERO).

## 8. Synchronization
Klasa: `CANONICAL` — moduły reconcile są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów — tylko model reconcile.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER`

## 12. Drift Detection
Model reconcile wykrywa rozjazd między warstwami CANON/DRIFT/HISTORY/DEBT. `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
