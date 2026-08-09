# security

> Katalog testów bezpieczeństwa — weryfikacja odporności platformy na zagrożenia.

## 1. Purpose
Przechowuje testy bezpieczeństwa (security tests), które weryfikują odporność platformy na zagrożenia: skanowanie podatności, testy penetracyjne, testy autoryzacji.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (skrypty testów + polityki bezpieczeństwa). Wyniki skanów to actual state (Runtime/CI). Polityki bezpieczeństwa żyją w `security/policies`.

## 4. Contains
Skrypty testów bezpieczeństwa, definicje testów autoryzacji/uwierzytelniania, konfiguracje skanerów.

## 5. Does Not Contain
Nie zawiera sekretów, kluczy, danych produkcyjnych. Wyniki skanów żyją w `security/scanning` / `artifacts/evidence`.

## 6. Dependencies
Polityki bezpieczeństwa (`security/policies`), narzędzia skanujące, środowiska testowe.

## 7. Consumers
CI/CD pipeline, zespół bezpieczeństwa, zespół platformy.

## 8. Synchronization
`CANONICAL` — skrypty testów są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych wymagań bezpieczeństwa, zmienia się przy ewolucji zagrożeń, wycofywany gdy test przestaje być aktualny.

## 10. Security
Wysoka wrażliwość — testy mogą ujawniać wektory ataku. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez CI: testy bezpieczeństwa nie przechodzą, skany wykrywają nowe podatności.

## Examples
`STATUS: UNDEFINED`
