# NEGATIVE TESTS — OPERATION CONFIG ZERO

> PHASE 25 — Testy negatywne konfiguracji w `/opt/Prod-ready/`.
> Zasada: **system musi FAIL na złą konfigurację (nie przechodzić cicho).**

## 1. Testy negatywne wykonane

### 1.1 Kompilator — hardcoded IP (NEG-COMPILER-IP)
- **Test:** wstawić hardcoded IP do canonical config.
- **Oczekiwane:** validate FAIL.
- **Wynik:** ✅ PASS — kompilator wykrywa hardcoded IP (regex pełnych adresów IPv4).

### 1.2 Kompilator — sekrety (NEG-COMPILER-SECRET)
- **Test:** wstawić sekret do canonical config.
- **Oczekiwane:** validate FAIL.
- **Wynik:** ✅ PASS — kompilator wykrywa sekrety.

### 1.3 Kompilator — niepoprawny YAML (NEG-COMPILER-YAML)
- **Test:** wstawić niepoprawny YAML.
- **Oczekiwane:** validate FAIL.
- **Wynik:** ✅ PASS — kompilator wykrywa niepoprawny YAML.

### 1.4 State — rollback z uszkodzonego backupu (NEG-STATE-ROLLBACK)
- **Test:** `state.sh rollback-negative`.
- **Oczekiwane:** FAIL (rollback z uszkodzonego backupu).
- **Wynik:** ✅ PASS — state subsystem wykrywa uszkodzony backup.

## 2. Testy negatywne brakujące (FALSE GATE)

### 2.1 Orphaned modules (NEG-FALSE-GATE)
- **Test:** wymusić FAIL w `tools/verify/git/*`, `security/*`, `structure/*`.
- **Oczekiwane:** FAIL propaguje do procesu nadrzędnego.
- **Wynik:** ❌ FAIL — moduły kończą się `say ""` zamiast `verify_module_exit`, więc FAIL nie propaguje. **FALSE GATE.**

### 2.2 Ghost modules (NEG-GHOST)
- **Test:** wymusić FAIL w `tools/verify/git/*` itd.
- **Oczekiwane:** verify.sh reconcile wykrywa FAIL.
- **Wynik:** ❌ FAIL — verify.sh nie uruchamia git/security/structure. **GHOST.**

### 2.3 CI drift (NEG-CI-DRIFT)
- **Test:** wprowadzić drift konfiguracji.
- **Oczekiwane:** CI drift.yml wykrywa.
- **Wynik:** ❌ FAIL — drift.yml to MOCK. **NIEWYKRYWALNY.**

## 3. Wnioski
- **Kompilator i state** — testy negatywne PASS (wykrywają złą konfigurację).
- **FALSE GATE** — 8 orphaned modules nie propagują FAIL (test negatywny FAIL).
- **GHOST** — git/security/structure nie wykonywane (test negatywny FAIL).
- **CI drift** — mock (test negatywny FAIL).

## 4. Rekomendacja
1. Naprawić FALSE GATE — dodać `verify_module_exit` do 8 orphaned modules.
2. Podłączyć ghost modules do verify.sh.
3. Wypełnić CI drift mock.
