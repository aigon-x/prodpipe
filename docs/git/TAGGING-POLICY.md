# Tagging Policy — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — polityka w fazie genesis.

## Cel
Definicja modelu tagów.

## Rodzaje tagów

```text
baseline
milestone
release
recovery
```

## Przykłady

```text
baseline-0.1.0
baseline-1.0.0
v1.0.0
recovery-YYYYMMDD
```

## Zasady
- Tagi produkcyjne mają być immutable
- `BASELINE-0.1.0` opisuje czysty stan Genesis repozytorium
- Nie nazywamy baseline `v1.0.0` — to nie jest jeszcze release
- Prefiksy tagów są **case-insensitive** (akceptowane `BASELINE-`, `baseline-`,
  `V1.0.0`, `v1.0.0` itd.) — decyzja z OPERATION RECONCILE ZERO (R5), aby
  kanoniczny tag `BASELINE-0.1.0` (uppercase) był zgodny z polityką
  (patrz `tools/verify/git/tags.sh` GIT-301).

## Status
**STATUS: FOUNDATION PLACEHOLDER** — nie zaimplementowano w pełni.
