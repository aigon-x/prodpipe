# tools/verify/debt

> Moduł skanera długu technicznego AIGON Production Platform.

## 1. Purpose
Skanuje repozytorium pod kątem długu technicznego: pliki legacy, pliki bez klasyfikacji, artefakty nieaktualne.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla skanera długu.

## 4. Contains
- `scanner.sh` — DEBT-001..014: skaner długu technicznego (legacy, pliki bez klasyfikacji, artefakty).
- `debt.sh` — agregacja i raportowanie długu.

## 5. Does Not Contain
Nie zawiera sekretów ani danych runtime.

## 6. Dependencies
Zależy od `bash`, `tools/verify/core/lib.sh`.

## 7. Consumers
`verify.sh`, proces certyfikacji długu technicznego.

## 8. Synchronization
Klasa: `CANONICAL` — moduły długu są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów — tylko skanowanie długu.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER`

## 12. Drift Detection
Wykrywanie rozjazdu między stanem długu (desired) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
