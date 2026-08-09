# canonical

> Kanoniczna materializacja stanu pożądanego (desired state) — pojedyncze źródło prawdy dla kontraktów, konfiguracji, schematów, polityk i manifestów.

## 1. Purpose
Centralny katalog kanonicznych artefaktów (kontrakty, config, schemas, policies, manifests, registry). Jest to materializacja Git = desired state, z której generowane są artefakty pochodne.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Ten katalog jest materializacją kanoniczną — nie jest drugim SoT, lecz odzwierciedleniem Git.

## 4. Contains
Podkatalogi: `contracts/`, `config/`, `schemas/`, `policies/`, `manifests/`, `registry/` — kanoniczne artefakty deklaratywne.

## 5. Does Not Contain
Runtime state, sekrety, dane generowane, cache, dane sesyjne. Nie jest rejestrem ani pamięcią.

## 6. Dependencies
Git (źródło), `shared/sync` (płaszczyzna synchronizacji).

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git; stan faktyczny odzwierciedlany w Runtime.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów — tylko schematy, szablony, referencje i polityki rotacji.

## 11. Recovery
Odzysk z Git (desired state) — pełna rekonstrukcja z historii repozytorium.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
