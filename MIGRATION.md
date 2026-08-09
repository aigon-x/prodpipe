# MIGRATION — AIGON Production Platform

> **STATUS: UNDEFINED** — migracja w fazie genesis. Ramy zdefiniowane; szczegóły w toku.

## Zasada

To repozytorium jest **nowym, czystym** workspace (`/opt/Prod-ready/`). **NIE jest migracją istniejącego kodu.** Legacy jest archiwizowane, nie kopiowane.

## Strategie migracji

| Strategia | Znaczenie |
|---|---|
| KEEP | Zostaje w nowej strukturze |
| MIGRATE | Przeniesione do nowej struktury |
| MERGE | Połączone z istniejącym |
| ADAPT | Zaadaptowane do nowych kontraktów |
| REPLACE | Zastąpione nowym |
| QUARANTINE | Odizolowane (kwarantanna) |
| ARCHIVE | Zarchiwizowane |
| DELETE | Usunięte (tylko po resurrection test) |

## Proces archiwizacji legacy

**DISCOVER → AST → CALL GRAPH → RUNTIME REACHABILITY → DEPLOYMENT REACHABILITY → DECISION → QUARANTINE → ARCHIVE → RESURRECTION TEST → DELETE**

- **Nigdy nie auto-delete przez grep/regex.**
- **Nic nie kasuj** — kwarantanna zamiast usuwania.
- **Resurrection test** — przed usunięciem, test odtworzenia.

## Granice

- **Nie kopiuj legacy do nowej struktury** — archiwizuj.
- **Nie twórz drugiego runtime / knowledge / memory / registry** — tylko po to, by wypełnić strukturę.

## Status

**STATUS: UNDEFINED** — ramy zdefiniowane; migracja w toku.
