# templates

> Szablony konfiguracji — źródło dla konfiguracji generowanych.

## 1. Purpose
Przechowuje szablony konfiguracji, z których generowane są konfiguracje (GENERATED).

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Kanoniczne szablony.

## 4. Contains
Szablony konfiguracji.

## 5. Does Not Contain
Dane instancyjne, sekrety, wygenerowane konfiguracje.

## 6. Dependencies
`config/canonical`, `config/schemas`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git; używane do generowania.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów — szablony zawierają referencje, nie sekrety.

## 11. Recovery
Odzysk z Git.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
