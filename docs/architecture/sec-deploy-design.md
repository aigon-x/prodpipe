# SEC-DEPLOY — fire drills security — design doc

> Design doc — źródło specyfikacji dla implementacji SEC-DEPLOY (fire drills security).
> Status: DESIGN (do implementacji).
> Pochodzenie: wymiar #3 Bezpieczeństwo (SEC D/A/R/C) + P0-2/P0-3 w `docs/audit/audyt-v1.md`.
> Uwaga: znaczenie liter D/A/R/C jest `UNRESOLVED` — patrz `docs/decisions/ARCHITECTURAL-KNOWLEDGE-GAP-SEC-DARC.md`. Domeny są **jawnie konfigurowalne**, nie zahardkodowane.

## Cel

Wymiar #3 Bezpieczeństwo wymaga **detection drills = 1.0** — wykrywanie ataków testowane, nie deklarowane. SEC-DEPLOY dostarcza mechanizm **fire drills**: wstrzykujemy kontrolowany "atak" (injection), sprawdzamy, czy system go wykrywa, i zapisujemy dowód (evidence). Jeżeli system nie wykryje wstrzykniętego ataku → FAIL (BLOCKING).

## Problem

SONDA sekcja C (SEC) i audyt-v1 P0-2/P0-3 orzekają: SEC-D/SoD, SEC-A, SEC-R, SEC-C **ABSENT** jako check ID. Detection drills = 1.0 nie istnieje. Bez fire drills nie ma dowodu, że system faktycznie wykrywa ataki — jest tylko deklaracja.

## Pipeline drill

Każdy drill przechodzi przez pipeline:

```text
PRE-FLIGHT → INJECT → DETECT → WALIDACJA → EVIDENCE → DESTROY
```

| Faza | Opis | Fail-closed |
|---|---|---|
| **PRE-FLIGHT** | Sprawdź, czy środowisko jest gotowe (config, katalog wtrysków, brak pozostałości po poprzednim drillu) | brak gotowości → FAIL |
| **INJECT** | Wstrzyknij kontrolowany "atak" (np. plik z sekretem, wpis w logu, podejrzany grant) | brak wtrysku → FAIL |
| **DETECT** | Uruchom odpowiedni check security (secrets.sh, credentials.sh itd.) i sprawdź, czy wykrył wtrysk | brak wykrycia → FAIL (detection < 1.0) |
| **WALIDACJA** | Potwierdź, że wykrycie dotyczy wstrzykniętego artefaktu (nie fałszywego alarmu) | brak potwierdzenia → FAIL |
| **EVIDENCE** | Zapisz dowód (evidence_record): co wstrzyknięto, co wykryto, kiedy | brak evidence → FAIL |
| **DESTROY** | Usuń wstrzyknięty artefakt (rollback do stanu sprzed drillu) | brak usunięcia → FAIL (pozostałość = FAIL) |

## Domeny (jawnie konfigurowalne)

Domeny są **jawnie konfigurowalne** (z configu, nie hardcode). Proponowana robocza semantyka (HYPOTHESIS — patrz AKG):

```text
SEC-D = Detection
SEC-A = Authorization
SEC-R = Recovery
SEC-C = Confidentiality
```

Każda domena ma katalog wtrysków:

```text
tools/verify/security/drills/
├── detection/       # SEC-D-xx — intrusion, anomaly, compromise, detection drills
├── authorization/   # SEC-A-xx — privilege escalation, policy bypass, confused deputy, authority-chain
├── recovery/        # SEC-R-xx — credential recovery, node recovery, service recovery, incident recovery
└── confidentiality/ # SEC-C-xx — secret exposure, memory leakage, cross-tenant leakage, data exfiltration
```

> **Status:** PROPOSED CANONICALIZATION. Dopóki Suweren nie zatwierdzi znaczenia liter, domeny pozostają konfigurowalne (nazwy katalogów i check ID mogą się zmienić bez zmiany kodu).

## Check ID

| ID | Check | Co mierzy |
|---|---|---|
| SEC-D-01 | Detection drill: wstrzyknięty artefakt wykryty przez odpowiedni check | detection = 1.0 |
| SEC-A-01 | Authorization drill: nieautoryzowana operacja zablokowana | authorization enforcement |
| SEC-R-01 | Recovery drill: odzyskiwanie po wstrzykniętym uszkodzeniu | recovery działa |
| SEC-C-01 | Confidentiality drill: wstrzyknięty sekret wykryty | secret exposure detection |

> Uwaga: dokładne check ID zależą od decyzji Suwerena co do znaczenia liter. Powyższe to propozycja.

## Fail-closed

Gate jest **fail-closed**: brak katalogu wtrysków, brak configu, brak wykrycia wstrzykniętego ataku, brak evidence, brak DESTROY → FAIL (BLOCKING). Detection = 1.0 oznacza: **każdy** wstrzyknięty atak musi zostać wykryty.

## Konfiguracja

- Lista domen i ich wtrysków — z configu (registry.yaml), nie hardcode.
- Detection threshold — z configu (domyślnie 1.0).
- Katalog wtrysków — z configu.

## Integracja

- Moduł verify: `tools/verify/security/drills.sh` (orkiestrator drilli).
- Katalog wtrysków: `tools/verify/security/drills/`.
- Rejestracja w `gates.yaml` + `gen-profiles.sh`.
- Testy: `tools/verify/tests/test-security-drills.sh`.
- Dokumentacja: ten design doc + game-day runbook.

## Kolejność wdrożenia

1. Katalog wtrysków (po jednym na domenę).
2. Pipeline drill (PRE-FLIGHT → INJECT → DETECT → WALIDACJA → EVIDENCE → DESTROY).
3. Gate walidacyjny (drills.sh z checkami SEC-D/A/R/C, fail-closed).
4. Config (sekcja w registry.yaml).
5. Testy.
6. Rejestracja (gates.yaml + gen-profiles.sh).
7. Dokumentacja (game-day).
