# decisions

> Katalog rejestru decyzji architektonicznych (ADR) — udokumentowane decyzje governance.

## 1. Purpose
Przechowuje rejestr decyzji architektonicznych (ADR — Architecture Decision Records) — udokumentowane decyzje dotyczące architektury i governance platformy.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (ADR). ADR są częścią governance jako kod.

## 4. Contains
Dokumenty ADR (kontekst, decyzja, konsekwencje), rejestr decyzji.

## 4a. Rejestr ADR

| ADR | Tytuł | Status |
|---|---|---|
| [ADR-0001](ADR-0001-risk-prediction-s7.md) | Risk Prediction (S7) w System Quality Gates | PROPOSED |

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`governance/policies`, `governance/standards`.

## 7. Consumers
Zespół platformy, deweloperzy, nowi członkowie zespołu, audytorzy.

## 8. Synchronization
`CANONICAL` — ADR są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy każdej istotnej decyzji, zmienia się przez kontrolowany proces zmian, archiwizowany gdy decyzja przestaje obowiązywać.

## 10. Security
ADR mogą opisywać architekturę bezpieczeństwa. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: implementacja odbiega od udokumentowanych decyzji.

## Examples
`STATUS: UNDEFINED`
