# tools/verify/drift

> Moduł wykrywania rozjazdu (drift) AIGON Production Platform.

## 1. Purpose
Wykrywa rozjazd między desired state (git) a actual state (Runtime) dla kluczowych artefaktów konfiguracyjnych.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla wykrywania rozjazdu.

## 4. Contains
- `drift.sh` — wykrywanie rozjazdu między konfiguracją w git a faktycznym stanem.

## 5. Does Not Contain
Nie zawiera sekretów ani danych runtime.

## 6. Dependencies
Zależy od `bash`, `tools/verify/core/lib.sh`.

## 7. Consumers
`verify.sh`, proces certyfikacji spójności.

## 8. Synchronization
Klasa: `CANONICAL` — moduły drift są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów — tylko wykrywanie rozjazdu.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER`

## 12. Drift Detection
Ten moduł JEST mechanizmem wykrywania rozjazdu. `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
