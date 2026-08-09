# config

> Kanoniczna konfiguracja (CANONICAL) — pojedyncze źródło prawdy dla konfiguracji platformy.

## 1. Purpose
Przechowuje kanoniczną konfigurację platformy jako stan pożądany. Z niej generowane są konfiguracje pochodne (GENERATED) i lokalne (LOCAL).

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Kanoniczna konfiguracja jest jedynym źródłem — brak ręcznych plików typu `node01.env`.

## 4. Contains
Kanoniczne pliki konfiguracyjne (CANONICAL) dla całej platformy.

## 5. Does Not Contain
Konfiguracje GENERATED i LOCAL (te żyją w `config/generated` i `config/local`), sekrety, dane maszynowe.

## 6. Dependencies
`shared/canonical/schemas` (schematy konfiguracji), `config/templates`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git; generuje konfiguracje pochodne.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów — tylko referencje i szablony; sekrety poza Git.

## 11. Recovery
Odzysk z Git.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
