# tools/verify/structure

> Moduł weryfikacji struktury AIGON Production Platform.

## 1. Purpose
Weryfikuje kontrakty README: każdy katalog domenowy ma README z 12 wymaganymi sekcjami i markerem Status.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla struktury repozytorium.

## 4. Contains
- `readme.sh` — STR-001..003: kontrakt README (12 sekcji), wykluczenia katalogów strukturalnych.

## 5. Does Not Contain
Nie zawiera sekretów ani danych runtime.

## 6. Dependencies
Zależy od `bash`, `tools/verify/core/lib.sh`.

## 7. Consumers
`verify.sh`, proces certyfikacji struktury.

## 8. Synchronization
Klasa: `CANONICAL` — moduły struktury są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów — tylko weryfikacja struktury.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER`

## 12. Drift Detection
Wykrywanie rozjazdu między strukturą (desired) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
