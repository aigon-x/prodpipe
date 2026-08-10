# CLEAN ROOM — OPERATION CONFIG ZERO

> PHASE 28 — Clean room (czysty pokój) dla `/opt/Prod-ready/`.
> Zasada: **konfiguracja musi być odtwarzalna w czystym środowisku (bez maszynowych magic-defaultów).**

## 1. Definicja clean room
Clean room = środowisko, w którym konfiguracja jest odtwarzana **wyłącznie z kanonicznej** (bez zależności od maszyny, developerów, magic-defaultów, README).

## 2. Zasady clean room
- **Nie script/env/README/developer/machine/magic-default-driven** — konfiguracja pochodzi z `config/canonical/`.
- **Determinizm** — ta sama kanoniczna → ten sam wynik (fingerprint).
- **Brak sekretów w repo** — tylko SECRET_REFERENCE.
- **Brak hardcoded IP** — dynamiczne wartości nie są ręcznie utrzymywane.

## 3. Co jest clean room (PASS)

| Element | Clean room? | Uzasadnienie |
|---------|-------------|--------------|
| `config/canonical/platform.yaml` | ✅ TAK | Jedyny SoT, walidowany schema |
| `config-compiler.sh generate` | ✅ TAK | Deterministyczny, odtwarzalny |
| `state.sh init/migrate` | ✅ TAK | Odtwarzalny z migracji |
| `config/generated/` | ✅ TAK | Deterministycznie wyprowadzane |
| `state/data/canonical-state.db` | ✅ TAK | Odtwarzany z migracji |

## 4. Co NIE jest clean room (FAIL)

| Element | Clean room? | Problem |
|---------|-------------|---------|
| `tools/verify/debt/scanner.sh` | ❌ NIE | 40 legacy wartości hardcoded w skrypcie (nie w config) |
| `.git-hooks/*` | ❌ NIE | Shadow — nie zarejestrowane w config |
| `tools/verify/git|security|structure/*` | ❌ NIE | GHOST — nie wykonywane |
| CI workflows (drift/helios/release/security) | ❌ NIE | MOCK — placeholdery |
| `config/local/` | ❌ NIE | SHADOW — zadeklarowany, nieobecny |

## 5. Wnioski
- **Fundacja jest clean room** — kanoniczna, kompilator, state, artefakty.
- **Luki clean room** — legacy hardcoded, shadow hooks, ghost modules, CI mocki, config/local.

## 6. Rekomendacja
1. Przenieść legacy wartości do `config/canonical/legacy.yaml`.
2. Zarejestrować git hooks w config.
3. Podłączyć ghost modules.
4. Wypełnić CI mocki.
5. Utworzyć config/local/ lub usunąć z deklaracji.
