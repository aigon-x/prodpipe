# ARCHITECTURAL KNOWLEDGE GAP — SEC D/A/R/C

> Dokumentacja luki semantycznej w wymiarze #3 Bezpieczeństwo (SEC D/A/R/C).
> Status: **UNRESOLVED** — znaczenie liter nie jest kanonicznie rozstrzygnięte.
> Typ: ARCHITECTURAL KNOWLEDGE GAP (nie decyzja, nie implementacja).

## 1. Cel

Udokumentować lukę semantyczną wykrytą przed rozpoczęciem implementacji SEC-DEPLOY. Celem jest **zachowanie dowodów i niepewności**, a nie zgadywanie utraconej intencji autora. Zgodnie z zasadą epistemic governance: FACT / INFERENCE / HYPOTHESIS / UNKNOWN nie mogą się mieszać.

## 2. Kontekst

Wymiar #3 Bezpieczeństwo w `docs/architecture/aesthetics-plane-design.md` (wiersz 79) definiuje:

| # | Wymiar | Rodzina | Definicja "doskonałe" | Dowód (z evidence) |
|---|---|---|---|---|
| 3 | Bezpieczeństwo | SEC D/A/R/C | 3 niezależne domeny zaufania; decyzje exploit-aware (KEV/EPSS/reachability) | macierz 12×4 pełna; detection drills = 1.0 |

Termin **SEC D/A/R/C** pojawia się również w `docs/00-foundation/SONDA.md` (sekcja C) i `docs/audit/audyt-v1.md` (P0-2, P0-3).

## 3. SOURCE SEARCH — wyniki

Przeszukano następujące źródła w poszukiwaniu kanonicznej definicji liter D/A/R/C:

| Źródło | Wynik |
|---|---|
| Current repository (`/opt/Prod-ready`) | Brak definicji liter |
| Git history (wszystkie commity, `git log --all -S "SEC D/A/R/C"`) | Termin pojawił się w commit `0b6783c` bez definicji |
| ADR / `docs/decisions/` | Brak wpisu |
| Design docs (`docs/architecture/`) | Brak definicji liter |
| Code (`tools/verify/`) | Brak check ID SEC-D/SEC-A/SEC-R/SEC-C |
| Tests | Brak |
| Manifests / config (`config/`) | Brak |
| Generated docs | Brak |

**Wniosek (FACT):** Termin "SEC D/A/R/C" pojawił się w commit `0b6783c` (AESTHETICS PLANE integracja) **bez znalezionej definicji w dostępnych źródłach**. Nie wiadomo, czy znaczenie "zaginęło", czy nigdy nie zostało formalnie zapisane — to rozróżnienie jest celowe i nie wolno go zacierać.

## 4. CONFLICT-001 — 3 vs 4 domeny

| Pole | Wartość |
|---|---|
| **ID** | CONFLICT-001 |
| **Claim A** | Design document stwierdza: "3 niezależne domeny zaufania" |
| **Claim B** | SEC matrix definiuje: D/A/R/C = 4 litery (potencjalnie 4 domeny) |
| **Evidence** | Brak historycznej definicji |
| **Status** | CONTRADICTORY / UNRESOLVED |
| **Impact** | Architektura SEC-DEPLOY (liczba domen, struktura wtrysków) |
| **Resolution required** | Decyzja kanonicznego właściciela (Suweren) |

> **Uwaga:** Nie wolno automatycznie uznać, że "3 to literówka". To jest **hipoteza**, nie fakt. Rozbieżność 3 vs 4 jest zapisana jako CONFLICT-001 i wymaga decyzji właściciela.

## 5. Proponowana robocza semantyka (HYPOTHESIS — NIE zatwierdzona)

Jako **proponowaną roboczą semantykę** (do czasu decyzji Suwerena) przyjmuje się:

```text
SEC-D = Detection
SEC-A = Authorization
SEC-R = Recovery
SEC-C = Confidentiality
```

Uzasadnienie wyboru **Authorization** zamiast **Authentication**:
- W fire drills bezpieczeństwa testujemy nie tylko "kim jesteś?" (authentication), ale "czy w tej konkretnej sytuacji wolno ci wykonać tę operację?" (authorization).
- Authorization jest szersze i obejmuje privilege escalation, policy bypass, confused deputy, authority-chain drills.

> **Status:** PROPOSED CANONICALIZATION — dopóki Suweren nie zatwierdzi, litery pozostają `UNRESOLVED`, a SEC-DEPLOY musi być zbudowany tak, aby domeny były **jawnie konfigurowalne** (nie zahardkodowane).

## 6. Time Shifting / Temporal Fabric

To odkrycie jest przykładem, dlaczego potrzebny jest Temporal / Epistemic Fabric. System powinien móc powiedzieć:

```text
SEC-D/A/R/C

INTRODUCED:        commit 0b6783c
FIRST OBSERVED:    commit 0b6783c
DEFINITION:        UNKNOWN
FIRST IMPLEMENTATION: (SEC-DEPLOY — pending)
FIRST USAGE:       ...
CHANGES:           ...
INTERPRETATIONS:   [D=Detection/A=Authorization/R=Recovery/C=Confidentiality (proposed)]
CURRENT STATUS:    UNRESOLVED
```

Po decyzji Suwerena:

```text
2026-08-10
DECISION:          D=Detection, A=Authorization, R=Recovery, C=Confidentiality
DECISION SOURCE:   Sovereign decision
EFFECTIVE_FROM:    event #...
SUPERSEDES:        UNRESOLVED interpretation
```

**Nie kasujemy starej niepewności.** Historia mówi: "przez pewien czas znaczenie było nieznane; następnie zostało kanonicznie rozstrzygnięte". To jest bardziej wartościowe niż przepisywanie starego dokumentu.

## 7. Wpływ na SEC-DEPLOY

SEC-DEPLOY (fire drills security) projektowany jest z domenami **jawnie konfigurowalnymi**:

```text
SEC-DEPLOY
│
├── D — Detection
│   ├── intrusion detection
│   ├── anomaly detection
│   ├── compromise detection
│   └── detection drills
│
├── A — Authorization
│   ├── privilege escalation
│   ├── policy bypass
│   ├── confused deputy
│   └── authority-chain drills
│
├── R — Recovery
│   ├── credential recovery
│   ├── node recovery
│   ├── service recovery
│   └── incident recovery
│
└── C — Confidentiality
    ├── secret exposure
    ├── memory leakage
    ├── cross-tenant leakage
    └── data exfiltration
```

Powyższa struktura jest oznaczona jako **PROPOSED CANONICALIZATION** — dopóki Suweren nie zatwierdzi, domeny pozostają konfigurowalne, a nie sztywno zakodowane.

## 8. Rekomendacja

1. **Nie zgadywać** utraconej intencji autora.
2. **Oznaczyć** SEC D/A/R/C jako `UNRESOLVED` i zachować dowody (ten dokument).
3. **Zaprojektować** SEC-DEPLOY z jawnie konfigurowalnymi domenami.
4. **Zbudować** ARCHITECTURAL SEMANTICS GATE (osobny dokument) — aby wykrywać takie luki semantyczne zanim agent zacznie na ich podstawie budować kod.
5. **Czekać** na decyzję Suwerena co do kanonicznego znaczenia liter.

## 9. Status dokumentu

`STATUS: UNRESOLVED` — dokumentacja luki semantycznej. Nie jest decyzją ani implementacją. Po decyzji Suwerena dokument zostanie zaktualizowany o sekcję "DECISION" (bez kasowania sekcji niepewności).
