# UNIVERSALITY GAP — Raport

> **Faza:** B — UNIVERSALITY CERTIFICATION (przygotowanie)
> **Data:** 2026-08-10
> **Status:** **STOP** — wykryto GAP-y przed rozpoczęciem certyfikacji T01-T10
> **Decyzja Suwerena:** NIE naprawiać podczas certyfikacji. Najpierw pełny GAP report. Jeszcze nie robimy Prod-template.
> **Zasada:** PASS → dowód → następny test. FAIL → STOP → raport → decyzja. NIE ulepszamy skeletonu podczas certyfikacji.

---

## 1. Kontekst

Po zakończonej FAZIE A (SCAFFOLD CONTRACT, raport `scaffold-implementation.md` → **PASS**, 9/9 testów), Suweren dał zielone światło na **UNIVERSALITY CERTIFICATION** z ostrzejszą zasadą:

> "Certyfikujemy obecny skeleton. Nie ulepszamy go podczas certyfikacji. PASS → dowód → następny test. FAIL → STOP → raport → decyzja. Nie: FAIL → agent dopisuje mechanizm → ponownie testuje → PASS. Bo wtedy nigdy nie będziemy wiedzieli, czy pierwotny skeleton był dobry."

Przed rozpoczęciem certyfikacji 10 projektów (T01-T10) przeprowadzono **test przecieku** (AIGON leakage) oraz **test verify w świeżym projekcie**. Oba ujawniły GAP-y, które blokują certyfikację uniwersalności.

**Zgodnie z decyzją Suwerena: STOP + raport GAP. NIE naprawiam niczego.**

---

## 2. Podsumowanie GAP-ów

| # | Problem | Gdzie | Severity | Root cause | Dowód | Właściciel |
|---|---------|-------|----------|------------|-------|------------|
| 1 | **AIGON leakage** — świeży projekt z template'a dostaje całą platformę AIGON | Template | **P0** | Template jest kopią platformy AIGON, nie uniwersalnym skeletonem | 557 plików / 14 katalogów / 223 pliki z "aigon" | Template |
| 2 | **Verify requires Git** — verify.sh wymaga `.git`, ale scaffold celowo tworzy projekt bez `.git` | Verify / Scaffold contract | **P0** | Boundary mismatch: verify zakłada git repo, scaffold izoluje projekt od git | `cd: FATAL: not a git repository` (exit 141) | Verify / Scaffold contract |
| 3 | **Executable bits** — SELF-001 zgłasza WARN "Skrypt nie jest wykonywalny (bit x)" | Template / Scaffold | **P1** | Uprawnienia nie są w pełni reprodukowane; bit x to WARN (nie BLOCKING) w SELF-001 | SELF-001 WARN | Scaffold / Template |

---

## 3. GAP #1 — AIGON leakage (P0)

### Problem
Świeży projekt wygenerowany z template'a dostaje **całą platformę AIGON** — nie jest uniwersalnym skeletonem projektowym, tylko kopią platformy.

### Dowód
Test przecieku na świeżym projekcie (scaffold z manifestem `minimal`):
- **557 plików** skopiowanych do nowego projektu.
- **14 AIGON-specific katalogów**: `agents/`, `mesh/`, `models/`, `system/`, `deployment/`, `observability/`, `operations/`, `security/`, `shared/`, `business/`, `apps/`, `archive/`, `filesystem/`, `governance/`.
- **223 pliki** zawierające "aigon" w treści.
- `README.md` nowego projektu mówi **"AIGON Production Platform"**.

W samym template: **1139 plików** zawiera "aigon" (grep -ril, bez `.git/`).

### Root cause
Template (`/opt/Prod-ready`) **jest** platformą AIGON — nie jest neutralnym, uniwersalnym skeletonem projektowym. Scaffold kopiuje cały template (minus `COPY_EXCLUDE`), więc każdy nowy projekt dziedziczy całą platformę.

### Wpływ na certyfikację
- **Wymiar "No AIGON leakage"** (jeden z 6 wymiarów certyfikacji) → **FAIL** dla każdego z 10 projektów.
- Świeży projekt nie jest "czysty" — nie spełnia wymogu izolacji od platformy.
- Certyfikacja uniwersalności **nie może się rozpocząć** dopóki template nie jest neutralny.

### Właściciel
**Template** — wymaga decyzji: czy template ma być neutralnym skeletonem (bez AIGON), czy scaffold ma filtrować AIGON-specific pliki.

---

## 4. GAP #2 — Verify requires Git (P0)

### Problem
`verify.sh` w świeżym projekcie kończy się błędem `cd: FATAL: not a git repository` (exit 141), bo wymaga `.git`. Ale scaffold **celowo** tworzy projekt bez `.git` (izolacja — SELF-CHECK weryfikuje brak `.git`).

### Dowód
```
$ timeout ./verify.sh   # w świeżym projekcie
cd: FATAL: not a git repository
(exit 141)
```

### Root cause
**Boundary mismatch** między dwoma kontraktami:
- **Scaffold contract:** nowy projekt NIE ma `.git` (izolacja, SELF-CHECK to weryfikuje).
- **Verify contract:** `verify.sh` zakłada, że działa w git repo (`cd "$ROOT"` + operacje git).

Te dwa kontrakty są **sprzeczne** — świeży projekt nie może przejść verify, bo verify wymaga czegoś, czego scaffold celowo nie tworzy.

### Wpływ na certyfikację
- **Wymiar "Verify"** (jeden z 8 wymiarów docelowej tabeli) → **FAIL** dla każdego projektu.
- Świeży projekt nie może być zweryfikowany przez własne narzędzia.
- Konflikt kontraktów musi być rozwiązany **przed** certyfikacją.

### Właściciel
**Verify / Scaffold contract** — wymaga decyzji: czy scaffold ma tworzyć `.git`, czy verify ma działać bez `.git`.

---

## 5. GAP #3 — Executable bits (P1)

### Problem
SELF-001 (`self-profile-integrity.sh`) zgłasza WARN "Skrypt nie jest wykonywalny (bit x)" dla niektórych modułów w świeżym projekcie.

### Dowód
- Template ma **8 skryptów** z bit x (git mode `100755`): `.git-hooks/pre-commit`, `.git-hooks/pre-push`, `.git-hooks/validate-sot`, `system/control-plane/state/state.sh`, `tests/test_state.sh`, `tools/repository-integrity.sh`, `tools/security/secret-scan.sh`, `tools/verify/verify.sh`.
- Świeży projekt zachowuje `775` na wszystkich 8.
- Ale SELF-001 zgłasza WARN dla modułów, których skrypty **nie mają** bitu x.

### Root cause
- **SELF-001** sprawdza `[ ! -x "$VERIFY_DIR/$script" ]` → warn "Skrypt nie jest wykonywalny (bit x)".
- Komentarz w SELF-001 wyjaśnia: bit x to **WARN (nie BLOCKING)**, bo moduły są uruchamiane przez `bash "$script"`, więc bit x nie jest wymagany do działania.
- Jednak scaffold **nie reprodukuje w pełni** uprawnień — część modułów w świeżym projekcie nie ma bitu x, mimo że template je ma.

### Wpływ na certyfikację
- **Wymiar "Reproducibility"** (jeden z 8 wymiarów) → częściowy FAIL (WARN, nie BLOCKING).
- Nie blokuje działania (moduły uruchamiane przez `bash`), ale jest sygnałem, że uprawnienia nie są w pełni reprodukowane.
- Severity **P1** (nie P0) — nie blokuje, ale wymaga decyzji.

### Właściciel
**Scaffold / Template** — wymaga decyzji: czy scaffold ma reprodukować bity x w pełni, czy SELF-001 ma być dostosowany.

---

## 6. Wpływ na certyfikację (6 wymiarów)

| Wymiar | Status | GAP |
|--------|--------|-----|
| Project isolation | ⚠️ | GAP #1 (projekt dziedziczy całą platformę) |
| Config isolation | ⚠️ | GAP #1 (config AIGON w świeżym projekcie) |
| Gate portability | ❌ | GAP #2 (verify wymaga .git) |
| Documentation portability | ⚠️ | GAP #1 (README "AIGON Production Platform") |
| No AIGON leakage | ❌ | GAP #1 (223 pliki z "aigon") |
| Template immutability | ✅ | Brak GAP (Template Drift Guard działa, P0) |

**Wniosek:** 4 z 6 wymiarów są zagrożone przez GAP-y. Certyfikacja **nie może się rozpocząć** w obecnym stanie.

---

## 7. Docelowa tabela (10 × 8) — stan obecny

| Projekt | Scaffold | Config | Gates | Docs | Isolation | Repro | AIGON leak | Template drift |
|---------|----------|--------|-------|------|-----------|-------|------------|----------------|
| T01 minimal | ✅ | ⚠️ | ❌ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ |
| T02 cli | ✅ | ⚠️ | ❌ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ |
| T03 rust-backend | ✅ | ⚠️ | ❌ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ |
| T04 python-service | ✅ | ⚠️ | ❌ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ |
| T05 web | ✅ | ⚠️ | ❌ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ |
| T06 ai | ✅ | ⚠️ | ❌ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ |
| T07 distributed | ✅ | ⚠️ | ❌ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ |
| T08 data | ✅ | ⚠️ | ❌ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ |
| T09 multi-service | ✅ | ⚠️ | ❌ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ |
| T10 filesystem | ✅ | ⚠️ | ❌ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ |

**Legenda:** ✅ PASS · ⚠️ zagrożone (GAP #1/#3) · ❌ FAIL (GAP #2)

**Uwaga:** Tabela jest **projekcją** — GAP-y #1/#2 są wspólne dla wszystkich typów (template-level), więc każdy projekt dziedziczy te same problemy. Nie uruchamiałem pełnej certyfikacji T01-T10, bo GAP-y blokują ją na poziomie template.

---

## 8. Rekomendacja (do decyzji Suwerena)

Zgodnie z zasadą certyfikacji (FAIL → STOP → raport → decyzja), **nie naprawiam niczego**. Przedstawiam opcje do decyzji:

### Opcja A — Neutralny template (rekomendowana dla uniwersalności)
Przebudować template na **neutralny skeleton** (bez AIGON-specific plików/katalogów), a platformę AIGON przenieść do osobnego katalogu (np. `platform/`), który scaffold **nie kopiuje**. To spełnia wymiar "No AIGON leakage" i czyni template prawdziwie uniwersalnym.

### Opcja B — Scaffold filtruje AIGON
Zostawić template jako platformę, ale rozszerzyć `COPY_EXCLUDE` o AIGON-specific katalogi/pliki. Scaffold kopiuje tylko neutralny podzbiór. Mniej inwazyjne, ale template nadal "pachnie" AIGON.

### Opcja C — Zaakceptować AIGON leakage
Uznać, że każdy nowy projekt jest "projektem AIGON" i dziedziczy platformę. To **odrzuca** wymiar "No AIGON leakage" — sprzeczne z celem uniwersalności.

### GAP #2 (Verify requires Git) — niezależna decyzja
- **C2a:** Scaffold tworzy `.git` w nowym projekcie (rezygnacja z izolacji git).
- **C2b:** Verify działa bez `.git` (tryb "standalone").
- **C2c:** Verify wymaga jawnie zainicjalizowanego git (dokumentacja, nie automat).

### GAP #3 (Executable bits) — niezależna decyzja
- **C3a:** Scaffold reprodukuje bity x w pełni (z `git ls-files -s` mode).
- **C3b:** SELF-001 ignoruje bit x (już jest WARN, nie BLOCKING).
- **C3c:** Zaakceptować WARN jako sygnał, nie błąd.

---

## 9. Co NIE zostało zrobione (zgodnie z decyzją)

- ❌ **NIE naprawiłem** żadnego GAP-a.
- ❌ **NIE uruchomiłem** pełnej certyfikacji T01-T10 (blokowana przez GAP-y).
- ❌ **NIE zrobiłem** Prod-template (Suweren: "jeszcze nie robimy Prod-template").
- ❌ **NIE dodałem** T11 (zamknięta lista typów — nie rozszerzam).

---

## VERDICT: **STOP — GAP-y wykryte**

Certyfikacja uniwersalności **nie może się rozpocząć** w obecnym stanie. Wykryto 3 GAP-y (2× P0, 1× P1), które blokują 4 z 6 wymiarów certyfikacji.

**Zgodnie z decyzją Suwerena: czekam na decyzję przed jakąkolwiek naprawą lub kontynuacją certyfikacji.**
