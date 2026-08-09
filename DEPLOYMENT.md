# DEPLOYMENT — AIGON Production Platform

> **STATUS: UNDEFINED** — deployment w fazie genesis. Ramy zdefiniowane; szczegóły w toku.

## Zasady

- **RING 0-3** — pierścienie wdrożeniowe (od najbardziej krytycznego do najmniej).
- **Immutable image digests** — brak `:latest` w produkcji. Każdy obraz ma niezmienny digest.
- **Compose profiles** — profile wdrożeniowe.
- **Git = desired state** — deployment jest deklaratywny, w `deployment/`.

## Struktura

| Katalog | Rola |
|---|---|
| `deployment/rings/` | Definicje pierścieni RING 0-3 |
| `deployment/profiles/` | Profile wdrożeniowe (compose profiles) |
| `deployment/images/` | Definicje obrazów (immutable digests) |
| `deployment/manifests/` | Manifesty wdrożeniowe |
| `deployment/helm/` | Helm charts |
| `deployment/terraform/` | Terraform (infrastruktura) |
| `deployment/scripts/` | Skrypty wdrożeniowe |
| `deployment/secrets/` | Referencje sekretów (NIGDY wartości) |
| `deployment/backup/` | Backup |
| `deployment/restore/` | Restore |

## Łańcuch merge (deployment)

PR → Build → Unit → Integration → Regression → SOT → Drift → Feature → Three Witnesses → HELIOS → BASELINE → MERGE

## Granice

- **Brak `:latest` image w produkcji** (CI odrzuca).
- **Brak hardcoded IP / hostname / node count / kernel count**.
- **Brak sekretów w repo** — tylko referencje.

## Status

**STATUS: UNDEFINED** — ramy zdefiniowane; implementacja w toku.
