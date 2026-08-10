# canonical

> Kanoniczna konfiguracja (CANONICAL) — pojedyncze źródło prawdy dla konfiguracji.
> **STATUS: CANONICAL** — zdefiniowano model CANONICAL/GENERATED/LOCAL + platform.yaml.

## 1. Purpose
Przechowuje kanoniczną konfigurację platformy jako stan pożądany (DESIRED). Z niej generowane są
konfiguracje pochodne (GENERATED) i lokalne (LOCAL).

## 2. Owner
`@aigon/platform` (single-owner Source of Truth).

## 3. Source of Truth
Git (desired state). Kanoniczna konfiguracja jest jedynym źródłem — brak ręcznych plików typu `node01.env`.

## 4. Contains
- `platform.yaml` — kanoniczna konfiguracja platformy (CANONICAL_CONFIG)
- `schema.md` — model CANONICAL/GENERATED/LOCAL
- `README.md` — ten dokument

## 5. Does Not Contain
Konfiguracje GENERATED i LOCAL (te w `config/generated` i `config/local`), sekrety, dane maszynowe,
hardcoded IP / hostname / node count / kernel count.

## 6. Dependencies
`config/schemas`, `config/templates`, `tools/config/config-compiler.sh`.

## 7. Consumers
`tools/config/config-compiler.sh` (walidacja + generacja), `system/control-plane/state/` (OBSERVED),
`tools/verify/` (drift detection).

## 8. Synchronization
`CANONICAL` — synchronizowane z Git; generuje konfiguracje pochodne przez `config-compiler.sh generate`.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów — tylko referencje i szablony; sekrety poza Git (SECRET_REFERENCE).

## 11. Recovery
Odzysk z Git. Fingerprint deterministyczny: `config-compiler.sh fingerprint`.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `tools/verify/drift/drift.sh` + `system/control-plane/state/`.

## Examples
`config/examples/example.md` — przykład canonical config.
