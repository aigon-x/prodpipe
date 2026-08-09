# skills

> Współdzielone skille (umiejętności) platformy AIGON Production.

## 1. Purpose
Przechowuje współdzielone skille (software-development, operations, security, audit, communication) jako artefakty deklaratywne.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Skille jako artefakty deklaratywne.

## 4. Contains
Podkatalogi: `software-development/`, `operations/`, `security/`, `audit/`, `communication/`.

## 5. Does Not Contain
Runtime state, sekrety, dane sesyjne.

## 6. Dependencies
`shared/canonical` (kontrakty, schematy).

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
