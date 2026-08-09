# schemas

> Kanoniczne schematy (JSON Schema / protobuf / itp.) dla kontraktów i konfiguracji.

## 1. Purpose
Przechowuje kanoniczne schematy walidujące kontrakty, konfiguracje i dane platformy.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Kanoniczne schematy.

## 4. Contains
Definicje schematów (JSON Schema, protobuf, itp.) dla kontraktów i konfiguracji.

## 5. Does Not Contain
Dane instancyjne, runtime state, sekrety.

## 6. Dependencies
`shared/canonical/contracts`, `shared/canonical/config`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów — tylko definicje schematów.

## 11. Recovery
Odzysk z Git.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
