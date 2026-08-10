# tools/security

> Narzędzia bezpieczeństwa AIGON Production Platform — skanery sekretów i poświadczeń.

## 1. Purpose
Dostarcza narzędzia bezpieczeństwa: skaner sekretów (`secret-scan.sh`), weryfikację poświadczeń i integralności bezpieczeństwa.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla narzędzi bezpieczeństwa.

## 4. Contains
- `secret-scan.sh` — skaner sekretów (STAGE 0, FOUNDATION PLACEHOLDER).

## 5. Does Not Contain
Nie zawiera sekretów ani poświadczeń — tylko skrypty skanujące i referencje.

## 6. Dependencies
Zależy od `bash`, narzędzi standardowych POSIX, `tools/verify/security/` (moduły weryfikacji).

## 7. Consumers
Operatorzy, CI/CD, proces certyfikacji bezpieczeństwa.

## 8. Synchronization
Klasa: `CANONICAL` — narzędzia bezpieczeństwa są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Narzędzia skanują sekrety; same nie przechowują sekretów.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania narzędzi bezpieczeństwa.

## 12. Drift Detection
Wykrywanie rozjazdu między narzędziami bezpieczeństwa (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
