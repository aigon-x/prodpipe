# architecture

> Katalog dokumentacji architektonicznej — opisy architektury platformy.

## 1. Purpose
Przechowuje dokumentację architektoniczną — opisy architektury platformy, diagramy, decyzje architektoniczne i modele.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (dokumentacja). Dokumentacja opisuje desired state; faktyczny stan to actual state (Runtime).

## 4. Contains
Dokumenty architektoniczne, diagramy (C4, UML), opisy komponentów, modele.

- `observability-factory-vision.md` — wizja OBSERVABILITY/TELEMETRY FACTORY (przyszły etap po MONITOR PLANE).

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`governance/decisions`, `docs/reference`.

## 7. Consumers
Zespół platformy, deweloperzy, nowi członkowie zespołu, audytorzy.

## 8. Synchronization
`CANONICAL` — dokumentacja jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy zmianach architektury, zmienia się przy ewolucji, wycofywana gdy nieaktualna.

## 10. Security
Dokumentacja może opisywać architekturę bezpieczeństwa. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: dokumentacja odbiega od faktycznej architektury.

## Examples
`STATUS: UNDEFINED`
