# ownership

> Katalog mapy własności domen — definicja właścicieli poszczególnych obszarów platformy.

## 1. Purpose
Przechowuje mapę własności domen (ownership) — definicję właścicieli poszczególnych obszarów, katalogów i komponentów platformy (CODEOWNERS / OWNERSHIP.md).

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (mapa własności). Mapa własności jest częścią governance jako kod.

## 4. Contains
Pliki CODEOWNERS, OWNERSHIP.md, mapy odpowiedzialności domen.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`STATUS: UNDEFINED`

## 7. Consumers
Wszystkie zespoły, CI/CD (egzekwowanie review), nowi członkowie zespołu.

## 8. Synchronization
`CANONICAL` — mapa własności jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu struktury zespołów, zmienia się przy zmianach organizacyjnych, wycofywany gdy obszar znika.

## 10. Security
Mapa własności może ujawniać strukturę zespołów. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: zmiany w strukturze bez aktualizacji mapy własności.

## Examples
`STATUS: UNDEFINED`
