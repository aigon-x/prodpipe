# Git / Runtime Boundary — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — granica w fazie genesis.

## Cel
Jednoznaczne rozdzielenie odpowiedzialności Git vs Runtime vs AIGON-X-FS.

## Git owns

```text
source
contracts
schemas
declarative config
deployment definitions
tests
policies-as-code
```

## Runtime owns

```text
actual state
actual topology
actual health
actual registry state
telemetry
evidence
dynamic node identity
dynamic runtime metrics
```

## AIGON-X-FS later owns

```text
persistent distributed runtime data
knowledge
memory
evidence/artifacts where appropriate
user/tenant data
```

## Zasada
Git jest Source of Truth dla SOURCE CODE i DECLARATIVE ENGINEERING ARTIFACTS.
Git NIE jest Source of Truth dla dynamicznego Runtime State.
Nigdy nie twórz mechanizmu, który traktuje Git jako zamiennik Runtime Registry.

## Status
**STATUS: FOUNDATION PLACEHOLDER** — granica udokumentowana, nie zaimplementowana.
