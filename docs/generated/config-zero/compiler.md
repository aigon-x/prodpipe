# COMPILER — OPERATION CONFIG ZERO

> PHASE 20 — Deterministyczny kompilator konfiguracji w `/opt/Prod-ready/`.
> Zasada: **fingerprint(A) == fingerprint(B) — deterministyczna kompilacja.**

## 1. Kompilator

**Plik:** `tools/config/config-compiler.sh`
**Status:** ✅ CANONICAL (działa, przetestowany)

## 2. Subkomendy

| Subkomenda | Opis | Wynik |
|------------|------|-------|
| `validate` | Waliduje canonical config | `validate PASS` (0 FAIL, 1 WARN jsonschema) |
| `generate` | Generuje DERIVED config | `config/generated/platform.generated.yaml` + `MANIFEST.generated.txt` |
| `fingerprint` | Oblicza deterministyczny fingerprint | `f99d3c82dfe7f03d6df6de8d2b2fb0701cede59f588134f55d121d02ea60e98b` |
| `status` | Pokazuje status pipeline | Canonical/Generated dirs, fingerprint, pipeline |

## 3. Pipeline
```
CANONICAL → VALIDATED → NORMALIZED → EFFECTIVE → GENERATED → OBSERVED
```
- **CANONICAL** — `config/canonical/platform.yaml`.
- **VALIDATED** — JSON Schema + brak sekretów + brak hardcoded IP.
- **NORMALIZED** — posortowany, bez komentarzy (deterministyczny).
- **EFFECTIVE** — zastosowana konfiguracja.
- **GENERATED** — `config/generated/platform.generated.yaml`.
- **OBSERVED** — zaobserwowana w runtime.

## 4. Fingerprint
- **Metoda:** sha256 nad znormalizowanym (posortowanym, bez komentarzy) canonical YAML.
- **Determinizm:** `fingerprint(A) == fingerprint(B)` — ta sama kanoniczna → ten sam fingerprint.
- **Wartość:** `f99d3c82dfe7f03d6df6de8d2b2fb0701cede59f588134f55d121d02ea60e98b`.
- **Zastosowanie:** wykrywanie driftu (rozjazd fingerprintu = drift).

## 5. Walidacja (validate)
- Schema istnieje.
- YAML jest poprawny.
- JSON Schema (gdy jsonschema dostępny).
- **Brak sekretów** (SECRET_REFERENCE tylko).
- **Brak hardcoded IP** (pełne adresy IPv4).

## 6. Artefakty GENERATED
- `config/generated/platform.generated.yaml` — DERIVED config.
- `config/generated/MANIFEST.generated.txt` — manifest.
- **Klasa:** GENERATED (gitignored, deterministycznie wyprowadzane).

## 7. Testy
- `validate` → PASS (0 FAIL, 1 WARN jsonschema).
- `generate` → produkuje DERIVED config.
- `fingerprint` → deterministyczny (`f99d3c82...`).
- `status` → pokazuje pipeline.

## 8. Wnioski
- **Kompilator działa** — deterministyczny, walidujący, generujący.
- **Fingerprint deterministyczny** — `fingerprint(A) == fingerprint(B)`.
- **Brak sekretów i hardcoded IP** w canonical config.

## 9. Rekomendacja
1. Podłączyć kompilator do CI (wypełnić mock).
2. Dodać `legacy.yaml` do kompilacji (gdy powstanie).
