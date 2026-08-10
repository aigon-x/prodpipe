# SHADOW SYSTEM AUDIT — OPERATION CONFIG ZERO

> PHASE 16 — Audyt systemów cieni (shadow systems) w `/opt/Prod-ready/`.
> Klasyfikacja: `SHADOW` — element, który istnieje, ale nie jest zarejestrowany w konfiguracji kanonicznej / nie ma właściciela / nie jest wykonywany.

## 1. Cel
Zidentyfikować wszystkie shadow systems — elementy, które istnieją w repo, ale nie są zarejestrowane w `config/canonical/platform.yaml`, nie mają właściciela, lub nie są wykonywane przez główny pipeline.

## 2. Metoda
- Skan `.git-hooks/*` — hooki git (shadow, bo nie są zarejestrowane w config).
- Skan `tools/verify/*` — moduły verify (shadow, bo nie są wykonywane).
- Skan `config/*` — katalogi konfiguracyjne.
- Skan `system/control-plane/state/*` — state subsystem.
- Porównanie z `config/canonical/platform.yaml` (co jest zarejestrowane).

## 3. Wynik — 3 SHADOW (git hooks)

Wykryto **3 shadow systems** w `.git-hooks/`:

| # | Plik | Status | Problem |
|---|------|--------|---------|
| 1 | `.git-hooks/validate-sot` | SHADOW | Nie zarejestrowany w config; wywoływany przez CI (sot.yml, ci.yml) ale nie przez `tools/verify` |
| 2 | `.git-hooks/pre-commit` | SHADOW | Nie zarejestrowany w config; nie jest aktywnym hookiem git (`.git/hooks/` nie jest podłączony) |
| 3 | `.git-hooks/pre-push` | SHADOW | Nie zarejestrowany w config; nie jest aktywnym hookiem git |

**Kluczowe ustalenie:** `.git-hooks/` to **katalog źródłowy** hooków, ale **nie jest podłączony** do `.git/hooks/` (git nie używa `.git-hooks/` automatycznie). Hooki są **shadow** — istnieją, ale nie są aktywne w lokalnym git.

## 4. Inne shadow systems

### 4.1 Orphaned verify modules (GHOST)
8 modułów `tools/verify/git/*`, `tools/verify/security/*`, `tools/verify/structure/*` istnieją, ale **nie są wykonywane** przez `verify.sh` (który uruchamia tylko reconcile/drift/history/debt). To shadow systems — kod istnieje, ale nie działa.

### 4.2 `verify_profile_modules` (GHOST)
Funkcja w `core/profiles.sh` jest zdefiniowana, ale **nigdy nie wywoływana**. Profile L0-L4 nie są aktywowane.

### 4.3 `config/local/` (SHADOW)
Katalog `config/local/` jest zadeklarowany w kompilatorze (`Local dir: config/local`), ale nie istnieje w repo. To shadow — zadeklarowany, ale nieobecny.

### 4.4 `config/generated/` (GENERATED, gitignored)
Artefakty kompilatora są gitignored — poprawne (klasa GENERATED), ale wymagają rekompilacji po zmianie kanonicznej.

## 5. Wnioski
- **3 SHADOW** git hooks — istnieją, ale nie są aktywne (nie podłączone do `.git/hooks/`).
- **8 GHOST** verify modules — istnieją, ale nie są wykonywane.
- **1 GHOST** — `verify_profile_modules` nigdy nie wywoływana.
- **1 SHADOW** — `config/local/` zadeklarowany, ale nieobecny.

## 6. Rekomendacja
1. **Zarejestrować git hooks** w `config/canonical/platform.yaml` (sekcja `git_hooks`).
2. **Podłączyć hooki** do `.git/hooks/` (symlink lub instalacja) — lub jawnie oznaczyć jako nieaktywne.
3. **Podłączyć orphaned modules** do `verify.sh`.
4. **Wywołać `verify_profile_modules`**.
5. **Utworzyć `config/local/`** lub usunąć z deklaracji kompilatora.
