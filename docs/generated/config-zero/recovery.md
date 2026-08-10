# RECOVERY — OPERATION CONFIG ZERO

> PHASE 26 — Odzyskiwanie konfiguracji w `/opt/Prod-ready/`.
> Zasada: **unrecoverable config → max 6/10 w score modelu. Konfiguracja musi być odtwarzalna.**

## 1. Mechanizmy odzyskiwania

### 1.1 Rekompilacja z kanonicznej (RECOVERY-COMPILER)
- **Źródło:** `config/canonical/platform.yaml` (jedyny SoT).
- **Mechanizm:** `tools/config/config-compiler.sh generate`.
- **Wynik:** odtwarza `config/generated/platform.generated.yaml` + `MANIFEST.generated.txt`.
- **Determinizm:** fingerprint `f99d3c82...` — ta sama kanoniczna → ten sam artefakt.
- **Status:** ✅ RECOVERABLE.

### 1.2 State restore (RECOVERY-STATE)
- **Źródło:** migracje SQL + snapshoty.
- **Mechanizm:** `state.sh restore SID`, `state.sh backup-restore-test`.
- **Wynik:** przywraca bazę SQLite z backupu snapshotu.
- **Status:** ✅ RECOVERABLE (REAL backup->restore->verify test).

### 1.3 State rollback (RECOVERY-ROLLBACK)
- **Mechanizm:** `state.sh rollback-test` (REAL rollback test).
- **Wynik:** cofa generację.
- **Status:** ✅ RECOVERABLE.

### 1.4 Git recovery (RECOVERY-GIT)
- **Źródło:** Git (desired state).
- **Mechanizm:** `git checkout` / `git revert`.
- **Wynik:** odtwarza desired state.
- **Status:** ✅ RECOVERABLE.

## 2. Odzyskiwanie z migracji
- **Schema jest migracyjna** — każda zmiana to nowy plik w `migrations/`.
- **NIGDY ręcznych zmian schematu** — tylko przez migracje.
- **Odzysk:** Git (desired) + migracje + snapshoty — pełna rekonstrukcja z historii repozytorium i bazy.

## 3. Wnioski
- **Konfiguracja jest RECOVERABLE** — rekompilacja z kanonicznej, state restore, rollback, git.
- **Determinizm** — ta sama kanoniczna → ten sam artefakt.
- **Migracje** — schema migracyjna, odtwarzalna.

## 4. Rekomendacja
1. Dodać test odzyskiwania do CI (rekompilacja → porównanie fingerprintu).
2. Udokumentować procedurę odzyskiwania w README.
