# Sync Schema — AIGON Production Platform

> **STATUS: UNDEFINED** — schema w fazie genesis. Placeholder.

## Klasy synchronizacji

| Klasa | Znaczenie |
|---|---|
| CANONICAL | Jedno źródło prawdy, replikowane |
| REPLICATED | Kopia canonical, synchronizowana |
| GENERATED | Pochodna, generowana |
| CACHE | Pamięć podręczna, odtwarzalna |
| SESSION | Stan sesji, efemeryczny |
| EPHEMERAL | Tymczasowy, nietrwały |

## Zasady

- `shared/` = kanoniczna materializacja + replikacja + płaszczyzna sync. **NIE jest drugim SoT.**
- Każdy katalog `shared/` musi mieć oznaczoną klasę synchronizacji.
- **Sync matrix** — macierz synchronizacji między Git (desired) a Runtime (actual).

## Status
**STATUS: UNDEFINED** — nie zaimplementowano.
