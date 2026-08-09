# digests

> Katalog sum kontrolnych — rejestr digestów artefaktów i obrazów.

## 1. Purpose
Przechowuje sumy kontrolne (digests) — rejestr digestów artefaktów, obrazów i plików do weryfikacji integralności.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (rejestr digestów). Faktyczne digesty artefaktów to actual state (Runtime/CI).

## 4. Contains
Sumy kontrolne (SHA256), rejestry digestów, manifesty podpisów.

## 5. Does Not Contain
Nie zawiera samych artefaktów, stanu runtime, sekretów.

## 6. Dependencies
`artifacts/manifests`, `tools/ci`.

## 7. Consumers
CI/CD pipeline, zespół bezpieczeństwa, narzędzia weryfikacji.

## 8. Synchronization
`GENERATED` — digesty są generowane z artefaktów przez CI; rejestr jest `CANONICAL` w git.

## 9. Lifecycle
Powstaje przy budowie artefaktów, zmienia się przy nowych wersjach, wycofywany gdy artefakt znika.

## 10. Security
Digesty służą weryfikacji integralności. Dostęp ograniczony do zespołu.

## 11. Recovery
Regenerowane z artefaktów; rejestr odzyskiwany z git.

## 12. Drift Detection
Drift wykrywany przez weryfikację: digesty artefaktów nie zgadzają się z rejestrem.

## Examples
`STATUS: UNDEFINED`
