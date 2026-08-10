# canonical-state

> Canonical State Foundation — warstwa canonical operational state platformy AIGON Production Platform.
> SQLite = canonical operational state. Git = desired state (source). AIGON-X-FS = actual state (artifact plane, przyszłość).

## 1. Purpose
Pojedyncze źródło prawdy dla **canonical operational state** — stanu pożądanego (desired) i zaobserwowanego (observed) platformy, z pełnym modelem tożsamości, pochodzenia (provenance), generacji i snapshotów. Jest to warstwa pośrednia między Git (desired state) a AIGON-X-FS (actual state).

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny canonical-state nie jest jeszcze przypisany w CODEOWNERS / OWNERSHIP.md.

## 3. Source of Truth
SQLite (canonical operational state). **Git = desired state (source artifacts), SQLite = canonical operational state, AIGON-X-FS = actual state (artifact plane).** SQLite przechowuje metadata/referencje; AIGON-X-FS (przyszłość) przechowuje payload.

## 4. Contains
- `schema.sql` — canonical schema (migracyjna, wersjonowana)
- `migrations/` — sekwencja migracji (0001_initial.sql, ...)
- `state.sh` — StateStore CLI (init / migrate / generation / snapshot / hash / verify)
- `lib.sh` — współdzielone funkcje StateStore
- `tests/` — testy PHASE B11
- `data/` — lokalna baza SQLite (NIGDY commitowana, w .gitignore)

## 5. Does Not Contain
- Kod produkcyjny AIGON-X (runtime, kernely, agenci) — NIE migrujemy.
- Sekrety (klucze, tokeny, hasła) — tylko referencje.
- Payload artefaktów — to domena AIGON-X-FS (przyszłość).
- Drugi Source of Truth / rejestr / pamięć.

## 6. Dependencies
Git (desired state), `system/registry`, `system/control-plane`, `config/canonical`. Zależności szczegółowe w podkatalogach.

## 7. Consumers
`STATUS: UNDEFINED` — przyszli konsumenci: `system/control-plane`, `system/registry`, `system/observability`, `tools/verify`.

## 8. Synchronization
Klasa: `CANONICAL` — synchronizowane z Git (desired state); stan faktyczny odzwierciedlany w Runtime (actual state).

## 9. Lifecycle
Stan powstaje z Git (desired), zmienia się przez PR/commit, generacja rośnie przy każdej zmianie canonical state, snapshoty tworzone przy ważnych punktach.

## 10. Security
Brak sekretów — tylko schematy, referencje, polityki rotacji. Tożsamość przez `system/identity`, autoryzacja przez `system/security`.

## 11. Recovery
Odzysk z Git (desired state) + migracje + snapshoty — pełna rekonstrukcja z historii repozytorium i bazy.

## 12. Drift Detection
Porównanie Git (desired) vs SQLite (canonical) vs Runtime (actual) przez `tools/verify reconcile`.

## Examples
`STATUS: UNDEFINED` — brak znanych przykładów użycia (repo nowe, nic nie zaimplementowane).
