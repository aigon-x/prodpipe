# contract

> Katalog testów kontraktowych — weryfikacja zgodności kontraktów API między dostawcą a konsumentem.

## 1. Purpose
Przechowuje testy kontraktowe (contract tests), które weryfikują, że kontrakty API (schematy, sygnatury) są zgodne między dostawcą a konsumentem usługi.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kontrakty + testy). Kontrakty są częścią Public Platform Contract. Runtime = actual state (faktyczne odpowiedzi API).

## 4. Contains
Definicje kontraktów (schematy OpenAPI/JSON Schema), testy kontraktowe, przykładowe ładunki (payloads).

## 5. Does Not Contain
Nie zawiera testów jednostkowych/integracyjnych, danych produkcyjnych, sekretów.

## 6. Dependencies
Definicje kontraktów API, schematy, `tests/fixtures`.

## 7. Consumers
CI/CD pipeline, dostawcy i konsumenci API, zespół platformy.

## 8. Synchronization
`CANONICAL` — kontrakty i testy są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowego kontraktu, zmienia się przy zmianach API (wersjonowanie), wycofywany gdy kontrakt znika.

## 10. Security
Kontrakty mogą definiować wymagania bezpieczeństwa (auth, uprawnienia). Nie zawierają sekretów.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez CI: testy kontraktowe nie przechodzą, gdy dostawca i konsument rozjeżdżają się w interpretacji kontraktu.

## Examples
`STATUS: UNDEFINED`
