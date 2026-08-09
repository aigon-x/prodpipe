# incidents

> Katalog rejestrów incydentów bezpieczeństwa — ślad zdarzeń i reakcji.

## 1. Purpose
Przechowuje rejestry incydentów bezpieczeństwa — ślad zdarzeń bezpieczeństwa, analiz i reakcji na nie.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (rejestry incydentów). Faktyczne incydenty to actual state (Runtime).

## 4. Contains
Rejestry incydentów, analizy post-mortem, harmonogramy reakcji, lekcje wyciągnięte.

## 5. Does Not Contain
Nie zawiera sekretów, danych biznesowych, stanu runtime.

## 6. Dependencies
`security/policies`, `security/audit`.

## 7. Consumers
Zespół bezpieczeństwa, zespół platformy, zarząd.

## 8. Synchronization
`CANONICAL` — rejestry incydentów są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy każdym incydencie, zmienia się przy aktualizacjach analiz, archiwizowany gdy zamknięty.

## 10. Security
Wysoka wrażliwość — rejestry incydentów mogą ujawniać słabości. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: incydenty bez udokumentowanej reakcji.

## Examples
`STATUS: UNDEFINED`
