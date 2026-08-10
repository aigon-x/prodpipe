# SEC-DEPLOY — Game Day Runbook

> Runbook dla fire drills security (SEC-DEPLOY).
> Status: DESIGN (do implementacji).
> Pochodzenie: wymiar #3 Bezpieczeństwo (SEC D/A/R/C) — detection drills = 1.0.
> Uwaga: znaczenie liter D/A/R/C jest `UNRESOLVED` — patrz `docs/decisions/ARCHITECTURAL-KNOWLEDGE-GAP-SEC-DARC.md`.

## Cel

Game day to **zaplanowane, kontrolowane ćwiczenie** wykrywania ataków. Wstrzykujemy kontrolowany "atak" (injection), sprawdzamy, czy system go wykrywa, i zapisujemy dowód. Detection = 1.0 oznacza: **każdy** wstrzyknięty atak musi zostać wykryty.

## Kiedy uruchamiać

- Przy każdym releasie tier-1.
- Przy zmianie architektury bezpieczeństwa.
- Cyklicznie (rytm per tier).

## Pipeline drill

```text
PRE-FLIGHT → INJECT → DETECT → WALIDACJA → EVIDENCE → DESTROY
```

### 1. PRE-FLIGHT

- Sprawdź, czy config SEC-DEPLOY istnieje (registry.yaml).
- Sprawdź, czy katalog wtrysków istnieje (`tools/verify/security/drills/`).
- Sprawdź, czy nie ma pozostałości po poprzednim drillu (DESTROY nie wykonany).
- **Fail-closed:** brak gotowości → FAIL.

### 2. INJECT

- Wybierz wtrysk z katalogu wtrysków (po jednym na domenę).
- Wstrzyknij kontrolowany "atak" (np. plik z sekretem, wpis w logu, podejrzany grant).
- Zapisz, co wstrzyknięto (artefakt, lokalizacja, timestamp).
- **Fail-closed:** brak wtrysku → FAIL.

### 3. DETECT

- Uruchom odpowiedni check security (secrets.sh, credentials.sh itd.).
- Sprawdź, czy check wykrył wstrzyknięty artefakt.
- **Fail-closed:** brak wykrycia → FAIL (detection < 1.0).

### 4. WALIDACJA

- Potwierdź, że wykrycie dotyczy wstrzykniętego artefaktu (nie fałszywego alarmu).
- **Fail-closed:** brak potwierdzenia → FAIL.

### 5. EVIDENCE

- Zapisz dowód (evidence_record): co wstrzyknięto, co wykryto, kiedy.
- **Fail-closed:** brak evidence → FAIL.

### 6. DESTROY

- Usuń wstrzyknięty artefakt (rollback do stanu sprzed drillu).
- **Fail-closed:** brak usunięcia → FAIL (pozostałość = FAIL).

## Domeny wtrysków

Domeny są **jawnie konfigurowalne** (z configu, nie hardcode). Proponowana robocza semantyka (HYPOTHESIS):

| Domena | Katalog | Przykładowe wtryski |
|---|---|---|
| Detection | `drills/detection/` | intrusion, anomaly, compromise, detection drills |
| Authorization | `drills/authorization/` | privilege escalation, policy bypass, confused deputy, authority-chain |
| Recovery | `drills/recovery/` | credential recovery, node recovery, service recovery, incident recovery |
| Confidentiality | `drills/confidentiality/` | secret exposure, memory leakage, cross-tenant leakage, data exfiltration |

## Wynik

- **PASS:** wszystkie wtryski wykryte, evidence zapisane, DESTROY wykonany.
- **FAIL:** co najmniej jeden wtrysk niewykryty, brak evidence, lub pozostałość po drillu.

## Raport

Każdy game day kończy się raportem:

```text
Game Day: <data>
Domeny: [Detection, Authorization, Recovery, Confidentiality]
Wtryski: <liczba>
Wykryte: <liczba>
Detection: <wykryte/wtryski>  (wymagane = 1.0)
Evidence: <liczba wpisów>
DESTROY: <OK/FAIL>
Wynik: PASS/FAIL
```
