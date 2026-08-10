# decisions

> Katalog dokumentacji decyzji — rozszerzona dokumentacja decyzji architektonicznych.

## 1. Purpose
Przechowuje dokumentację decyzji — rozszerzone opisy decyzji architektonicznych i technicznych, uzupełniające rejestr ADR w `governance/decisions`.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (dokumentacja). Dokumentacja jest częścią desired state w repo.

## 4. Contains
Dokumenty decyzji, rozszerzone ADR, analizy opcji, uzasadnienia.

Rejestr ADR (kanoniczny): `governance/decisions/` — patrz [ADR-0001 Risk Prediction (S7)](../governance/decisions/ADR-0001-risk-prediction-s7.md).

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`governance/decisions`, `docs/architecture`.

## 7. Consumers
Zespół platformy, deweloperzy, audytorzy.

## 8. Synchronization
`CANONICAL` — dokumentacja jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy każdej istotnej decyzji, zmienia się przez kontrolowany proces zmian, wycofywana gdy decyzja przestaje obowiązywać.

## 10. Security
Dokumentacja decyzji może opisywać architekturę bezpieczeństwa. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: implementacja odbiega od udokumentowanych decyzji.

## Examples
`STATUS: UNDEFINED`
