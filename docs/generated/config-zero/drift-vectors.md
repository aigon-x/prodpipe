# DRIFT VECTORS — OPERATION CONFIG ZERO

> PHASE 17 — Wektory driftu konfiguracji w `/opt/Prod-ready/`.
> Model: DESIRED / EFFECTIVE / OBSERVED. Drift = rozjazd między tymi trzema poziomami.

## 1. Cel
Zidentyfikować wszystkie wektory, wzdłuż których konfiguracja może dryfować (rozjechać się między desired/effective/observed), oraz mechanizmy ich wykrywania.

## 2. Model driftu
```
DESIRED (Git / config/canonical)  →  EFFECTIVE (zastosowana)  →  OBSERVED (Runtime)
```
Drift występuje, gdy:
- **DESIRED ≠ EFFECTIVE** — konfiguracja kanoniczna nie została zastosowana.
- **EFFECTIVE ≠ OBSERVED** — zastosowana konfiguracja nie zgadza się z runtime.
- **DESIRED ≠ OBSERVED** — konfiguracja kanoniczna nie zgadza się z runtime.

## 3. Wektory driftu

### 3.1 V1 — Fingerprint kompilatora (DESIRED vs GENERATED)
- **Źródło:** `config/canonical/platform.yaml` vs `config/generated/platform.generated.yaml`
- **Mechanizm:** `tools/config/config-compiler.sh fingerprint` — deterministyczny hash.
- **Wykrywanie:** Rozjazd fingerprintu = drift. `fingerprint(A) == fingerprint(B)`.
- **Status:** WYKRYWALNY (kompilator działa).

### 3.2 V2 — State hash (DESIRED vs CANONICAL STATE)
- **Źródło:** Git (desired) vs `system/control-plane/state/data/canonical-state.db` (canonical state).
- **Mechanizm:** `state.sh hash` — state hash `c2129bd3...`.
- **Wykrywanie:** Rozjazd state hash = drift.
- **Status:** WYKRYWALNY (state.sh działa).

### 3.3 V3 — Legacy debt (HISTORY)
- **Źródło:** `tools/verify/debt/scanner.sh` — legacy porty/nazwy/hostname/endpointy/ENV.
- **Mechanizm:** DEBT-002/005/006/007/012/014.
- **Wykrywanie:** FAIL gdy legacy wartość jest znaleziona w repo.
- **Status:** WYKRYWALNY (6 FAIL w baseline).

### 3.4 V4 — Git desired vs Runtime actual (reconciliation)
- **Źródło:** `tools/verify/reconcile/reconcile.sh` + `drift/drift.sh`.
- **Mechanizm:** 4-warstwowy model CANON/DRIFT/HISTORY/DEBT.
- **Wykrywanie:** `verify.sh reconcile`.
- **Status:** WYKRYWALNY (działa, ale nie podłączony do CI).

### 3.5 V5 — CI drift (GHOST)
- **Źródło:** `.github/workflows/drift.yml` — **MOCK** (`echo "Drift: brak implementacji"`).
- **Mechanizm:** Brak — CI nie wykrywa driftu.
- **Wykrywanie:** NIE WYKRYWALNY w CI.
- **Status:** DRIFT NIEWYKRYWALNY (mock).

### 3.6 V6 — FALSE GATE (orphaned modules)
- **Źródło:** 8 orphaned verify modules (`git/*`, `security/*`, `structure/*`).
- **Mechanizm:** Kończą się `say ""` zamiast `verify_module_exit` — FAIL nie propaguje.
- **Wykrywanie:** FAIL-y nie są widoczne w procesie nadrzędnym.
- **Status:** DRIFT NIEWYKRYWALNY (FALSE GATE).

### 3.7 V7 — GHOST modules (nie wykonywane)
- **Źródło:** `verify.sh` nie uruchamia `git/*`, `security/*`, `structure/*`.
- **Mechanizm:** Moduły istnieją, ale nie są wykonywane.
- **Wykrywanie:** NIE WYKRYWALNY.
- **Status:** DRIFT NIEWYKRYWALNY (GHOST).

### 3.8 V8 — Shadow git hooks
- **Źródło:** `.git-hooks/*` — nie podłączone do `.git/hooks/`.
- **Mechanizm:** Hooki istnieją, ale nie są aktywne.
- **Wykrywanie:** NIE WYKRYWALNY (brak rejestracji).
- **Status:** DRIFT NIEWYKRYWALNY (SHADOW).

### 3.9 V9 — Hardcoded legacy (HARDCODED_INVALID)
- **Źródło:** `tools/verify/debt/scanner.sh` — 40 legacy wartości.
- **Mechanizm:** Wartości zakodowane w skrypcie, nie w config.
- **Wykrywanie:** DEBT-002/005/006/007/012/014 (FAIL).
- **Status:** WYKRYWALNY (ale źródło to skrypt, nie config).

### 3.10 V10 — Config/local (SHADOW)
- **Źródło:** `config/local/` zadeklarowany w kompilatorze, ale nieobecny.
- **Mechanizm:** Brak katalogu.
- **Wykrywanie:** NIE WYKRYWALNY.
- **Status:** DRIFT NIEWYKRYWALNY (SHADOW).

## 4. Macierz wykrywalności driftu

| Wektor | Źródło | Wykrywalny? | Mechanizm | Status |
|--------|--------|-------------|-----------|--------|
| V1 | platform.yaml vs generated | ✅ TAK | fingerprint | WYKRYWALNY |
| V2 | Git vs state.db | ✅ TAK | state hash | WYKRYWALNY |
| V3 | legacy w repo | ✅ TAK | DEBT-002/005/006/007/012/014 | WYKRYWALNY |
| V4 | Git vs Runtime | ✅ TAK | reconcile | WYKRYWALNY |
| V5 | CI drift | ❌ NIE | MOCK | NIEWYKRYWALNY |
| V6 | orphaned modules | ❌ NIE | FALSE GATE | NIEWYKRYWALNY |
| V7 | GHOST modules | ❌ NIE | nie wykonywane | NIEWYKRYWALNY |
| V8 | git hooks | ❌ NIE | SHADOW | NIEWYKRYWALNY |
| V9 | hardcoded legacy | ✅ TAK | DEBT | WYKRYWALNY |
| V10 | config/local | ❌ NIE | SHADOW | NIEWYKRYWALNY |

## 5. Wnioski
- **5 wektorów WYKRYWALNYCH** (V1-V4, V9) — kompilator, state hash, reconcile, debt.
- **5 wektorów NIEWYKRYWALNYCH** (V5-V8, V10) — CI mock, FALSE GATE, GHOST, shadow hooks, config/local.
- **Undetected config drift → max 5/10** w score modelu (penalty).

## 6. Rekomendacja
1. **Podłączyć CI drift** do `tools/verify reconcile` (wypełnić mock drift.yml).
2. **Naprawić FALSE GATE** — dodać `verify_module_exit` do 8 orphaned modules.
3. **Podłączyć GHOST modules** do `verify.sh`.
4. **Zarejestrować git hooks** w config.
5. **Utworzyć config/local/** lub usunąć z deklaracji.
