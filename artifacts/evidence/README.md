# evidence

> Katalog dowodów — rejestr dowodów zgodności i weryfikacji.

## 1. Purpose
Przechowuje dowody (evidence) — rejestr dowodów zgodności, weryfikacji i audytów technicznych platformy.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (rejestr dowodów). Faktyczne dowody to actual state (GENERATED przez CI/Runtime).

## 4. Contains
Raporty skanów, wyniki testów, dowody zgodności, certyfikaty.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`security/scanning`, `tests/`, `tools/ci`.

## 7. Consumers
Zespół bezpieczeństwa, audytorzy, zespół platformy.

## 8. Synchronization
`GENERATED` — dowody są generowane przez CI/Runtime; rejestr jest `CANONICAL` w git.

## 9. Lifecycle
Powstaje przy każdym przebiegu CI/audycie, zmienia się przy nowych wynikach, archiwizowany gdy nieaktualny.

## 10. Security
Dowody mogą ujawniać słabości. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Regenerowane przez CI/Runtime; rejestr odzyskiwany z git.

## 12. Drift Detection
Drift wykrywany przez audyt: dowody odbiegają od faktycznego stanu platformy.

## Examples
`STATUS: UNDEFINED`
