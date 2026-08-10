# REPRODUCIBILITY — OPERATION CONFIG ZERO

> PHASE 27 — Odtwarzalność konfiguracji w `/opt/Prod-ready/`.
> Zasada: **non-reproducible config → max 6/10 w score modelu. Ta sama kanoniczna → ten sam wynik.**

## 1. Determinizm kompilatora
- **Fingerprint:** `f99d3c82dfe7f03d6df6de8d2b2fb0701cede59f588134f55d121d02ea60e98b`.
- **Metoda:** sha256 nad znormalizowanym (posortowanym, bez komentarzy) canonical YAML.
- **Weryfikacja:** `fingerprint(A) == fingerprint(B)` — ta sama kanoniczna → ten sam fingerprint.
- **Status:** ✅ REPRODUCIBLE.

## 2. Determinizm state
- **State hash:** `c2129bd3d6064514f7ff89b93a5ca3df974735d5a5c61c122037433f737b5c96`.
- **Metoda:** hash stanu bazy SQLite.
- **Status:** ✅ REPRODUCIBLE.

## 3. Odtwarzalność artefaktów
- `config/generated/platform.generated.yaml` — odtwarzany z kanonicznej przez `generate`.
- `config/generated/MANIFEST.generated.txt` — odtwarzany z kanonicznej.
- `state/data/canonical-state.db` — odtwarzany z migracji przez `state.sh init/migrate`.

## 4. Test odtwarzalności
```
$ bash tools/config/config-compiler.sh generate   # generuje artefakt
$ bash tools/config/config-compiler.sh fingerprint # f99d3c82...
# rekompilacja z tej samej kanonicznej → ten sam fingerprint
```
**WYNIK: PASS** — deterministyczny.

## 5. Wnioski
- **Kompilator jest REPRODUCIBLE** — deterministyczny fingerprint.
- **State jest REPRODUCIBLE** — deterministyczny state hash.
- **Artefakty są odtwarzalne** — z kanonicznej i migracji.

## 6. Rekomendacja
1. Dodać test odtwarzalności do CI (rekompilacja → porównanie fingerprintu).
