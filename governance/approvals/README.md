# approvals

> Katalog rejestru zatwierdzeń — ślad procesu akceptacji zmian w governance.

## 1. Purpose
Przechowuje rejestr zatwierdzeń (approvals) — ślad procesu akceptacji zmian w politykach, standardach i decyzjach governance.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (rejestr zatwierdzeń). Rejestr jest częścią governance jako kod.

## 4. Contains
Dokumenty zatwierdzeń, rejestry decyzji akceptacyjnych, ślady procesu review.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`governance/policies`, `governance/standards`, `governance/decisions`.

## 7. Consumers
Zespół governance, audytorzy, zespół platformy.

## 8. Synchronization
`CANONICAL` — rejestr zatwierdzeń jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy każdej akceptacji zmiany, zmienia się przy nowych zatwierdzeniach, archiwizowany gdy nieaktualny.

## 10. Security
Rejestr może zawierać informacje o decydentach. Dostęp ograniczony do zespołu governance.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez audyt: zmiany w politykach bez odpowiadającego zatwierdzenia.

## Examples
`STATUS: UNDEFINED`
