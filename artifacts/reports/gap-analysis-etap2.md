# GAP ANALYSIS — Etap 2 (PROD-READY → PROD-SKEL)

> **Faza:** Etap 2 — GAP ANALYSIS + REMEDIATION PLAN + remediacja findings
> **Data:** 2026-08-10
> **Repo:** `/opt/Prod-ready` (AIGON Production Platform)
> **Cel:** Zidentyfikować i naprawić wszystkie luki blokujące certyfikację (Etap 3) oraz CI na GitHub (`aigon-x/prodpipe`).
> **Status:** W TOKU — 3 problemy CI naprawione, pozostałe FAIL-y do remediacji w Etapie 3.

---

## 1. Podsumowanie

Etap 2 ma na celu domknięcie luk między stanem lokalnym a wymaganiami certyfikacji (Etap 3) oraz CI na GitHubie. Diagnoza wykazała **3 problemy CI** (wszystkie naprawione) oraz **znane FAIL-y `verify.sh`** do remediacji w Etapie 3.

**Kluczowa obserwacja:** `verify.sh gates CI` przechodzi lokalnie (exit 0), ale GitHub CI zawodził na jobach `Drift`, `SOT — Source of Truth`, `CI — Build & Unit`. Root cause: **false positive w regexie IP** (numeracja sekcji dokumentu `10. Security` łapana jako adres IP) oraz **błędny ref `origin/main`** w świeżym checkout GitHub.

---

## 2. Naprawione problemy CI (3)

### 2.1. `validate-sot` — false positive IP (FIXED)

**Problem:** `config/canonical/platform.yaml:199: - "10. Security"` (numeracja sekcji README contract) był flagowany jako hardcoded IP.

**Root cause:** Regex `\b(10\.|100\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)` łapał prefiks `10. ` na początku linii — wymagał tylko 2 oktetów, nie pełnego adresu IP.

**Fix:** `.git-hooks/validate-sot` — zaostrzono regex do pełnego 4-oktetowego adresu IP:
```
\b(10\.|100\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)([0-9]{1,3}\.){2}[0-9]{1,3}\b
```
**Weryfikacja:** `./.git-hooks/validate-sot` → `[validate-sot] OK` (exit 0).

### 2.2. `ci.yml` architecture-boundaries — false positive IP + zły ref (FIXED)

**Problem:** Job `architecture-boundaries` zawodził na kroku "Reject hardcoded node count / IP" z dwóch powodów:
1. Ten sam luźny regex IP (`\b(10\.|100\.|192\.168\.)`) łapał `10. Security`.
2. `git diff --name-only origin/main...HEAD` — na GitHubie w świeżym checkout nie istnieje ref `origin/main` (tylko `main`), więc diff zwracał całą historię.

**Fix:** `.github/workflows/ci.yml`:
- Dodano `fetch-depth: 0` (pełna historia do diffa).
- Zastąpiono `origin/main` refem `${{ github.event.before }}` (SHA poprzedniego commita dla push / SHA bazy dla PR) we wszystkich 3 krokach diff.
- Zaostrzono regex IP do pełnego 4-oktetowego adresu.

### 2.3. Drift DRIFT-002 — README contract na pliku generowanym (FIXED)

**Problem:** `docs/graphs/README.md` nie miał 12 wymaganych sekcji README contract → DRIFT-002 FAIL (BLOCKING).

**Root cause:** `docs/graphs/README.md` jest **plikiem generowanym** (deterministic) przez `tools/explore/lib/graphs.sh` z `project-model.json`. Nie powinien mieć ręcznie dodawanych 12 sekcji.

**Fix:** `tools/verify/drift/drift.sh` — dodano `docs/graphs/` do `DRIFT_EXCLUDE`:
```
DRIFT_EXCLUDE='^(\.git-hooks/?|\.github/?|system/control-plane/state/?|tools/verify/?|tools/security/?|\.tools/?|config/generated/|docs/graphs/)'
```
**Weryfikacja:** `verify.sh drift` → `[PASS] DRIFT-002 README REQUIRED_MISSING` (0 FAIL, CERTIFICATION: PASS).

---

## 3. Znane FAIL-y `verify.sh` do remediacji (Etap 3)

Poniższe FAIL-y zostały zidentyfikowane wcześniej i wymagają remediacji przed certyfikacją (Etap 3). Są to luki w modułach weryfikacji, które nie przechodzą w profilach `full`/`release`/`genesis`.

| ID | Moduł | Opis | Priorytet |
|----|-------|------|-----------|
| STR-001/002 | security | Luki w walidacji security | P1 |
| ARCH-004/005/006 | architecture | Luki w walidacji architektury | P1 |
| D-001 | dependencies | Luka w walidacji zależności | P1 |
| R-001 | reproducibility | Luka w walidacji reprodukowalności | P1 |
| CONTRACT-002/003/006 | contracts | Luki w walidacji kontraktów | P1 |
| AEST-08-* | aesthetics | Luki w walidacji estetyki | P2 |
| CONS-01-* | consistency | Luki w walidacji spójności | P2 |
| SEM-005 | semantics | Luka w walidacji semantyki | P2 |
| TAX-015 | taxonomy | Luka w walidacji taksonomii | P2 |
| INT-01/02 | integration | Luki w walidacji integracji | P1 |
| EFF-001 | efficiency | Luka w walidacji wydajności | P2 |
| OBS-01 | observability | Luka w walidacji obserwowalności | P1 |

**Uwaga:** Pełna lista i szczegóły w `artifacts/reports/findings-register.md` (F-001..F-008+) oraz `artifacts/reports/universality-gap.md`.

---

## 4. REMEDIATION PLAN

### 4.1. Zrobione (Etap 2)
- [x] Fix `validate-sot` regex IP (4-oktetowy).
- [x] Fix `ci.yml` architecture-boundaries (ref + regex IP).
- [x] Fix `drift.sh` DRIFT_EXCLUDE (`docs/graphs/`).

### 4.2. Do zrobienia (Etap 3 — CERTIFICATION)
- [ ] Remediacja FAIL-ów `verify.sh` (STR, ARCH, D, R, CONTRACT, AEST, CONS, SEM, TAX, INT, EFF, OBS).
- [ ] `verify.sh full` PASS (wszystkie profile).
- [ ] Raporty certyfikacyjne.

---

## 5. Weryfikacja

| Check | Przed | Po |
|-------|-------|----|
| `./.git-hooks/validate-sot` | FAIL (false positive IP) | **PASS** (exit 0) |
| `verify.sh drift` | FAIL (DRIFT-002) | **PASS** (0 FAIL) |
| `verify.sh gates CI` | PASS lokalnie / FAIL na GitHub | **PASS** (149 PASS, 0 FAIL, exit=0) |
| GitHub CI (`aigon-x/prodpipe`) | FAIL (Drift, SOT, CI) | Do potwierdzenia po push |
