# development

> Katalog dokumentacji deweloperskiej — instrukcje dla deweloperów platformy.

## 1. Purpose
Przechowuje dokumentację deweloperską — instrukcje dla deweloperów, przewodniki konfiguracji środowiska, konwencje kodowania.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (dokumentacja). Dokumentacja jest częścią desired state w repo.

## 4. Contains
Przewodniki deweloperskie, instrukcje konfiguracji, konwencje kodowania, przewodniki kontrybucji.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`docs/architecture`, `docs/reference`.

## 7. Consumers
Deweloperzy, nowi członkowie zespołu, kontrybutorzy.

## 8. Synchronization
`CANONICAL` — dokumentacja jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu procesów deweloperskich, zmienia się przy zmianach narzędzi, wycofywana gdy nieaktualna.

## 10. Security
Dokumentacja może opisywać konfiguracje bezpieczeństwa. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: dokumentacja odbiega od faktycznych procesów.

## Examples
`STATUS: UNDEFINED`
