# Branch Policy — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — polityka w fazie genesis.

## Cel
Definicja modelu gałęzi dla kanonicznego repozytorium.

## Model

```text
main
 ├── feature/*
 ├── fix/*
 ├── migration/*
 ├── security/*
 └── release/*
```

- `main` = protected canonical branch
- Żadnego bezpośredniego `git push origin main` w normalnym workflow
- Zmiana musi przejść przez: branch → commit → validation → PR → required checks → review → merge

## Zasady
- `main` jest kanoniczną linią projektu
- Nie tworzymy `develop`, `master`, `release`, `staging` na tym etapie
- Prefiksy gałęzi wymuszane przez `.git-hooks/pre-push`

## Status
**STATUS: FOUNDATION PLACEHOLDER** — nie zaimplementowano w pełni.
