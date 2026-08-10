# GATE SYSTEM — World-Class Engineering Gate System v1.0

> System gate'ów jakości dla AIGON Production Platform. Automatycznie weryfikuje,
> egzekwuje i certyfikuje jakość repo. Każdy gate ma dowód wykonania (evidence).

## 1. Purpose
Egzekwuje jakość repo przez zbiór gate'ów (GATE-001..GATE-037), które weryfikują
spójność, bezpieczeństwo, strukturę, architekturę, stan i inne domeny. Każdy gate
jest zarejestrowany w registry (jedyne źródło prawdy), zaimplementowany jako skrypt,
podłączony do pipeline (enforcement) i ma dowód wykonania (evidence).

## 2. Owner
`STATUS: IMPLEMENTED` — system gate'ów jest aktywny i egzekwowany.

## 3. Source of Truth
`tools/verify/gates/registry.sh` jest JEDYNYM źródłem prawdy o gate'ach.
GATE-INTEGRITY meta-gate (GATE-001) weryfikuje: registry == implemented == wired == executed.

## 4. Contains
- `registry.sh` — rejestr gate'ów (37 wpisów, 22 pola tab-separated)
- `enforcement.sh` — egzekwowanie gate'ów per profil pipeline
- `evidence.sh` — generowanie evidence (dowód wykonania)
- `gate-integrity.sh` — meta-gate (GATE-001)
- `profile.sh` — profile pipeline (LOCAL_FAST / PRE_PUSH / CI / RELEASE)
- `report.sh` — generator raportów do artifacts/reports/gates/
- `domains/` — skrypty implementacji per domena (25 aktywnych + 12 PROPOSED)
- `tests/` — testy negatywne

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state. Evidence i raporty są generowane, nie ręczne.

## 6. Dependencies
Zależy od `tools/verify/core/` (lib.sh, profiles.sh, report.sh, reconcile.sh).

## 7. Consumers
CI (ci.yml, release.yml), git hooks (pre-commit, pre-push), operatorzy, architekci.

## 8. Synchronization
Klasa: `CANONICAL` — registry jest źródłem prawdy w git.

## 9. Lifecycle
Gate lifecycle: PROPOSED → IMPLEMENTED → WIRED → EXECUTED → ENFORCED → CERTIFIED → DEPRECATED → RETIRED.
Status per gate jest w polu 22 registry.

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w repo — GATE-005 (SECURITY) to egzekwuje.

## 11. Recovery
`STATUS: IMPLEMENTED` — GATE-013 (RECOVERY) weryfikuje procedury odzyskiwania.

## 12. Drift Detection
GATE-025 (EFFECTIVE-CONFIG) wykrywa drift między declared state a effective state.
GATE-021 (SYSTEM-TWIN) weryfikuje graf stanu z rzeczywistością.

## Użycie
```bash
# Wygeneruj evidence (dowód wykonania) dla wszystkich IMPLEMENTED gate'ów
bash tools/verify/gates/evidence.sh

# Egzekwuj gate'y dla profilu (LOCAL_FAST | PRE_PUSH | CI | RELEASE)
bash tools/verify/gates/enforcement.sh RELEASE

# Uruchom meta-gate GATE-INTEGRITY
bash tools/verify/gates/gate-integrity.sh

# Wygeneruj raporty do artifacts/reports/gates/
bash tools/verify/gates/report.sh

# Wypisz profile i ich gate'y
bash tools/verify/gates/profile.sh list
```

## Exit code konwencja
- `0` = PASS
- `1` = FAIL
- `2` = ERROR
- `3` = NOT_APPLICABLE

## NO FALSE GREEN
Zakazane: `|| true`, `set +e`, `continue-on-error: true`, ignorowany exit code,
puste testy, cichy skip. Każdy gate musi mieć realny dowód wykonania.
