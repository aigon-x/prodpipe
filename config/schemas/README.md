# schemas

> Schematy konfiguracji — kanoniczne definicje walidujące.

## 1. Purpose
Przechowuje schematy konfiguracji (JSON Schema / itp.) walidujące konfiguracje kanoniczne, generowane i lokalne.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Kanoniczne schematy.

## 4. Contains
Definicje schematów konfiguracji.

## 5. Does Not Contain
Dane instancyjne, sekrety.

## 6. Dependencies
`config/canonical`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Git.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
