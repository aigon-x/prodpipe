# standards

> Katalog standardów technicznych i organizacyjnych — normy, których musi przestrzegać platforma.

## 1. Purpose
Przechowuje standardy techniczne i organizacyjne — normy, konwencje i wymagania, których musi przestrzegać platforma i jej komponenty.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (standardy). Standardy są częścią governance jako kod.

## 4. Contains
Dokumenty standardów (nazewnictwo, formaty, konwencje kodowania, standardy API), wymagania zgodności.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`STATUS: UNDEFINED`

## 7. Consumers
Deweloperzy, zespół platformy, narzędzia walidacji (`tools/validation`), CI/CD pipeline.

## 8. Synchronization
`CANONICAL` — standardy są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych norm, zmienia się przez kontrolowany proces zmian, wycofywany gdy standard przestaje obowiązywać.

## 10. Security
Standardy mogą definiować wymagania bezpieczeństwa. Dostęp do zmian ograniczony.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez walidację: implementacje odbiegają od standardów.

## Examples
`STATUS: UNDEFINED`
