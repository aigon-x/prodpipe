# scripts

> Katalog skryptów operacyjnych — jednorazowe i pomocnicze skrypty.

## 1. Purpose
Przechowuje skrypty operacyjne — jednorazowe i pomocnicze skrypty do zadań administracyjnych i operacyjnych.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (skrypty). Skrypty są częścią desired state w repo.

## 4. Contains
Skrypty bash/python, jednorazowe narzędzia, pomocnicze komendy.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`tools/utilities`, `tools/automation`.

## 7. Consumers
Zespół operacyjny, deweloperzy, zespół platformy.

## 8. Synchronization
`CANONICAL` — skrypty są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych zadań, zmienia się przy zmianach operacyjnych, wycofywany gdy zadanie znika.

## 10. Security
Skrypty nie powinny zawierać sekretów. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: skrypty odbiegają od faktycznych procedur.

## Examples
`STATUS: UNDEFINED`
