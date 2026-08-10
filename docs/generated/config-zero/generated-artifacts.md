# GENERATED ARTIFACTS — OPERATION CONFIG ZERO

> PHASE 21 — Artefakty generowane w `/opt/Prod-ready/`.
> Klasa: `GENERATED` — deterministycznie wyprowadzane z kanonicznej, gitignored.

## 1. Artefakty GENERATED

| Artefakt | Źródło | Generator | Gitignored? |
|----------|--------|-----------|-------------|
| `config/generated/platform.generated.yaml` | `config/canonical/platform.yaml` | `config-compiler.sh generate` | ✅ TAK |
| `config/generated/MANIFEST.generated.txt` | `config/canonical/platform.yaml` | `config-compiler.sh generate` | ✅ TAK |
| `system/control-plane/state/data/canonical-state.db` | migracje SQL | `state.sh init/migrate` | ✅ TAK |

## 2. Zasada GENERATED
- **Deterministyczne:** ta sama kanoniczna → ten sam artefakt (fingerprint).
- **Gitignored:** nie commitowane (odtwarzalne z kanonicznej).
- **Nie SoT:** kanoniczna jest SoT; artefakt jest wyprowadzany.

## 3. Weryfikacja determinizmu
- `config-compiler.sh fingerprint` → `f99d3c82...` (deterministyczny).
- `state.sh hash` → `c2129bd3...` (state hash).
- Rekompilacja z tej samej kanonicznej → ten sam fingerprint.

## 4. Wnioski
- **Artefakty GENERATED są poprawnie sklasyfikowane** — gitignored, deterministyczne.
- **Kompilator i state subsystem** produkują artefakty z kanonicznej.

## 5. Rekomendacja
1. Dodać weryfikację determinizmu do CI (rekompilacja → porównanie fingerprintu).
