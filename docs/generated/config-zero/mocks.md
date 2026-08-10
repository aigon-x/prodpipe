# MOCK AUDIT — OPERATION CONFIG ZERO

> PHASE 15 — Audyt mocków (placeholderów) w `/opt/Prod-ready/`.
> Klasyfikacja: `MOCK` / `TEST_FIXTURE` / `HARDCODED_VALID`.

## 1. Cel
Zidentyfikować wszystkie mocki/placeholdery w repo, sklasyfikować je i ocenić, czy stanowią ryzyko produkcyjne (production mock path → max 3/10 w score modelu).

## 2. Metoda
- Skan `.github/workflows/*.yml` — placeholdery CI.
- Skan `tools/verify/*` — moduły verify (FALSE GATE / GHOST).
- Skan `config/*` — placeholdery konfiguracji.
- Skan `system/control-plane/state/*` — state subsystem.

## 3. Wynik — 7 MOCK (CI workflow placeholdery)

Wszystkie 7 mocków to **placeholdery w GitHub Actions workflows** — kroki `run: echo "..."` zamiast realnej implementacji.

| # | Plik | Krok | Treść mocka | Ryzyko |
|---|------|------|-------------|--------|
| 1 | `.github/workflows/ci.yml` | `unit` | `echo "Unit tests: brak implementacji (PHASE 9 — TEST SKELETON)"` | ŚREDNIE — CI przechodzi bez testów |
| 2 | `.github/workflows/drift.yml` | `drift` | `echo "Drift: brak implementacji (reconciliation engine...)"` | WYSOKIE — drift nie jest wykrywany |
| 3 | `.github/workflows/feature.yml` | `feature` | `echo "Feature: brak implementacji (PHASE 9 — TEST SKELETON)"` | ŚREDNIE |
| 4 | `.github/workflows/helios.yml` | `helios` | `echo "HELIOS: brak implementacji (final gate przed merge)"` | WYSOKIE — final gate nie działa |
| 5 | `.github/workflows/regression.yml` | `regression` | `echo "Regression: brak implementacji (PHASE 9 — TEST SKELETON)"` | ŚREDNIE |
| 6 | `.github/workflows/release.yml` | `release` | `echo "Release: brak implementacji (immutable image digests, deployment rings)"` | WYSOKIE — release nie działa |
| 7 | `.github/workflows/security.yml` | `security` | `echo "Security: brak implementacji (scanning — PHASE 9)"` | WYSOKIE — security scan nie działa |

## 4. Analiza ryzyka

### 4.1 Production mock path
Kroki CI z `echo "..."` zamiast realnej implementacji to **production mock path** — CI przechodzi (exit 0) bez faktycznego testowania. To jest **penalty: max 3/10** w score modelu dla wektorów zależnych od CI.

### 4.2 Krytyczne mocki
- **drift.yml** — drift detection jest kluczowy dla CONFIG ZERO (mechanizm wykrywania driftu). Mock = brak wykrywania driftu w CI.
- **helios.yml** — final gate przed merge. Mock = brak bramki jakości.
- **release.yml** — release pipeline. Mock = brak release.
- **security.yml** — security scanning. Mock = brak skanowania.

### 4.3 Mocki akceptowalne (TEST_FIXTURE)
Kroki `unit`, `feature`, `regression` to **TEST SKELETON** — szkielet testów, który ma być wypełniony w PHASE 9. Są to świadome placeholdery, nie dług.

## 5. FALSE GATE — 8 orphaned verify modules

Oprócz CI mocków, wykryto **8 orphaned verify modules**, które są **FALSE GATES** — kończą się `say ""` zamiast `verify_module_exit`, więc ich FAIL-y nie propagują się do procesu nadrzędnego:

| # | Moduł | Problem |
|---|-------|---------|
| 1 | `tools/verify/git/branches.sh` | Kończy się `say ""` — FAIL nie propaguje |
| 2 | `tools/verify/git/history.sh` | Kończy się `say ""` — FAIL nie propaguje |
| 3 | `tools/verify/git/integrity.sh` | Kończy się `say ""` — FAIL nie propaguje |
| 4 | `tools/verify/git/tags.sh` | Kończy się `say ""` — FAIL nie propaguje |
| 5 | `tools/verify/security/credentials.sh` | Kończy się `say ""` — FAIL nie propaguje |
| 6 | `tools/verify/security/history.sh` | Kończy się `say ""` — FAIL nie propaguje |
| 7 | `tools/verify/security/secrets.sh` | Kończy się `say ""` — FAIL nie propaguje |
| 8 | `tools/verify/structure/readme.sh` | Kończy się `say ""` — FAIL nie propaguje |

**Dodatkowo:** `verify.sh` **nie uruchamia** modułów `git/*`, `security/*`, `structure/*` — tylko `reconcile/drift/history/debt`. Więc te moduły są **GHOST** (nigdy nie wykonywane).

**GHOST:** `verify_profile_modules` w `core/profiles.sh` jest zdefiniowana, ale **nigdy nie wywoływana** — profile L0-L4 nie są aktywowane.

## 6. Wnioski
- **7 MOCK** w CI workflows — placeholdery, z czego 4 krytyczne (drift, helios, release, security).
- **8 FALSE GATE** orphaned verify modules — FAIL-y nie propagują.
- **1 GHOST** — `verify_profile_modules` nigdy nie wywoływana.
- **verify.sh nie uruchamia** git/security/structure — te moduły są martwe.

## 7. Rekomendacja
1. **Naprawić FALSE GATE**: dodać `verify_module_exit` na końcu 8 orphaned modules (zamiast `say ""`).
2. **Podłączyć moduły**: dodać `run_module "git/branches.sh"` itd. do `verify.sh reconcile`.
3. **Wywołać profile**: wywołać `verify_profile_modules` w `verify.sh`.
4. **Wypełnić mocki CI**: drift/helios/release/security muszą mieć realną implementację (podłączyć do `tools/verify`).
5. **Zarejestrować mocki** w `config/canonical/platform.yaml` (sekcja `verify_engine.mock_modules`).
