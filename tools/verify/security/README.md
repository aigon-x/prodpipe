# tools/verify/security

> Moduł weryfikacji bezpieczeństwa AIGON Production Platform.

## 1. Purpose
Weryfikuje bezpieczeństwo repozytorium: brak sekretów, brak poświadczeń, integralność historii bezpieczeństwa.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla weryfikacji bezpieczeństwa.

## 4. Contains
- `secrets.sh` — SEC-001..004: skaner sekretów w repozytorium.
- `credentials.sh` — SEC-201..208: weryfikacja poświadczeń.
- `history.sh` — SEC-101..102: weryfikacja historii bezpieczeństwa.

## 5. Does Not Contain
Nie zawiera sekretów ani poświadczeń — tylko logikę skanowania.

## 6. Dependencies
Zależy od `bash`, `tools/verify/core/lib.sh`, `tools/security/secret-scan.sh`.

## 7. Consumers
`verify.sh`, proces certyfikacji bezpieczeństwa.

## 8. Synchronization
Klasa: `CANONICAL` — moduły bezpieczeństwa są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Moduły skanują sekrety; same nie przechowują sekretów.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER`

## 12. Drift Detection
Wykrywanie rozjazdu między stanem bezpieczeństwa (desired) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
