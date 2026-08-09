# Large Files Policy — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — polityka w fazie genesis.

## Cel
Repo jest source repository, nie magazynem danych.

## Zakres polityki

```text
models
datasets
images
videos
database dumps
runtime snapshots
build artifacts
```

## Zasady
- Nie commituj dużych plików bez wyraźnego modelu artifact storage
- Rozdziel: co w Git, co w artifact registry, co w AIGON-X-FS, co w object storage
- Git LFS NIE jest włączany automatycznie — osobna decyzja architektoniczna

## Status
**STATUS: FOUNDATION PLACEHOLDER** — nie zaimplementowano w pełni.
