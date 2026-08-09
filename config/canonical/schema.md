# Canonical Configuration Schema — AIGON Production Platform

> **STATUS: UNDEFINED** — schema w fazie genesis. Placeholder.
> Zasada: **CANONICAL / GENERATED / LOCAL**. Canonical = jedyne źródło prawdy konfiguracji.

## Model

- **CANONICAL** — `config/canonical/` — jedyne źródło prawdy. Ręcznie utrzymywane, reviewowane, wersjonowane.
- **GENERATED** — `config/generated/` — pochodna, generowana z canonical. NIGDY ręcznie edytowana.
- **LOCAL** — `config/local/` — specyficzna dla maszyny. NIGDY commitowana.

## Zasady

- **Brak ręcznych `node01.env` itp.** — konfiguracja per-node jest generowana, nie ręczna.
- **Brak hardcoded IP / hostname / node count / kernel count** w canonical.
- **Brak sekretów** — tylko referencje.
- **Single-owner** — każda domena ma jednego właściciela konfiguracji.

## Struktura canonical

```yaml
# config/canonical/ — placeholder
version: 0.1.0
status: UNDEFINED
```

## Status
**STATUS: UNDEFINED** — nie zaimplementowano.
