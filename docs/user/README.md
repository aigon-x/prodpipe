# user

> Katalog dokumentacji użytkownika — instrukcje dla użytkowników platformy.

## 1. Purpose
Przechowuje dokumentację użytkownika — instrukcje, przewodniki i opisy funkcji dla użytkowników platformy.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (dokumentacja). Dokumentacja opisuje Public Platform Contract; faktyczne zachowanie to actual state (Runtime).

## 4. Contains
Instrukcje użytkownika, przewodniki, opisy funkcji, FAQ.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`business/contracts`, `docs/reference`.

## 7. Consumers
Użytkownicy platformy, warstwa biznesowa, zespół wsparcia.

## 8. Synchronization
`CANONICAL` — dokumentacja jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy dodawaniu nowych funkcji, zmienia się przy zmianach UX, wycofywana gdy funkcja znika.

## 10. Security
Dokumentacja użytkownika nie powinna zawierać informacji wrażliwych.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: dokumentacja odbiega od faktycznych funkcji.

## Examples
`STATUS: UNDEFINED`
