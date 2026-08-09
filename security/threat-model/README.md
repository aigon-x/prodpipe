# threat-model

> Katalog modeli zagrożeń — analizy wektorów ataku i ryzyk bezpieczeństwa.

## 1. Purpose
Przechowuje modele zagrożeń (threat models) — analizy wektorów ataku, ryzyk bezpieczeństwa i kontroli łagodzących dla platformy.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (modele zagrożeń). Modele są częścią governance bezpieczeństwa jako kod.

## 4. Contains
Modele zagrożeń (np. STRIDE), analizy ryzyka, mapowania kontroli łagodzących.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`security/policies`, `governance/decisions`.

## 7. Consumers
Zespół bezpieczeństwa, zespół platformy, deweloperzy.

## 8. Synchronization
`CANONICAL` — modele zagrożeń są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy zmianach architektury, zmienia się przy ewolucji zagrożeń, wycofywany gdy nieaktualny.

## 10. Security
Wysoka wrażliwość — modele zagrożeń ujawniają wektory ataku. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: architektura zmienia się bez aktualizacji modelu zagrożeń.

## Examples
`STATUS: UNDEFINED`
