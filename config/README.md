# config

> Katalog konfiguracyjny AIGON Production Platform — deklaratywna konfiguracja, schematy.

## 1. Purpose
Przechowuje deklaratywną konfigurację platformy: schematy, szablony, definicje konfiguracyjne. Jest to **jedyny źródło prawdy (Source of Truth)** dla konfiguracji deklaratywnej platformy.

## 2. Owner
`STATUS: CANONICAL` — właściciel: `@aigon/architecture` (patrz `OWNERSHIP.md`).

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla konfiguracji deklaratywnej. Runtime odzwierciedla actual state. `config/canonical/` = jedyny SoT dla konfiguracji kanonicznej.

## 4. Contains
- `canonical/` — konfiguracja kanoniczna (jedyny SoT): `platform.yaml` + README.
- `schemas/` — JSON Schema walidujące konfigurację kanoniczną: `platform.schema.json`.
- `templates/` — szablony konfiguracji.
- `examples/` — przykłady konfiguracji.
- `generated/` — **GENERATED** (gitignored) artefakty kompilatora: `platform.generated.yaml`, `MANIFEST.generated.txt`.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state. Sekrety są referencjami (SECRET_REFERENCE), nigdy wartościami.

## 6. Dependencies
Zależy od contracts, governance, deployment. Kompilator: `tools/config/config-compiler.sh`.

## 7. Consumers
Runtime, narzędzia wdrożeniowe, operatorzy, kompilator konfiguracji.

## 8. Synchronization
Klasa: `CANONICAL` — konfiguracja deklaratywna jest źródłem prawdy w git. Artefakty `generated/` są klasy `GENERATED` (deterministycznie wyprowadzane z kanonicznej).

## 9. Lifecycle
`STATUS: CANONICAL` — pipeline: CANONICAL→VALIDATED→NORMALIZED→EFFECTIVE→GENERATED→OBSERVED.

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i referencje. Kompilator waliduje brak sekretów i brak hardcoded IP.

## 11. Recovery
`STATUS: CANONICAL` — odzyskiwanie konfiguracji: rekompilacja z `config/canonical/platform.yaml` przez `tools/config/config-compiler.sh generate` (deterministyczna, fingerprint-porównywalna).

## 12. Drift Detection
Wykrywanie rozjazdu między konfiguracją (git) a faktycznym stanem (Runtime). Kompilator produkuje deterministyczny fingerprint; rozjazd fingerprintu = drift. `STATUS: CANONICAL`.

## Examples
`STATUS: CANONICAL` — patrz `config/examples/example.md`.
