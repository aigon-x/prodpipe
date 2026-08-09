# utilities

> Katalog narzędzi pomocniczych — wielokrotnie używane narzędzia.

## 1. Purpose
Przechowuje narzędzia pomocnicze (utilities) — wielokrotnie używane, ponownie wykorzystywane narzędzia i biblioteki pomocnicze.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (narzędzia). Narzędzia są częścią desired state w repo.

## 4. Contains
Narzędzia pomocnicze, biblioteki, moduły wielokrotnego użytku.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`tools/scripts`, `tools/automation`.

## 7. Consumers
Zespół platformy, deweloperzy, inne narzędzia.

## 8. Synchronization
`CANONICAL` — narzędzia są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych potrzeb, zmienia się przy ewolucji, wycofywany gdy nieużywany.

## 10. Security
Narzędzia nie powinny zawierać sekretów. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: narzędzia odbiegają od faktycznych potrzeb.

## Examples
`STATUS: UNDEFINED`
