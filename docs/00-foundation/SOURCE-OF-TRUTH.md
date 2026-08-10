# SOURCE-OF-TRUTH (Foundation) — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — rozszerzenie root `SOURCE-OF-TRUTH.md`.
> **Owner: UNASSIGNED**

## 1. Relacja do root SOURCE-OF-TRUTH.md

Kanoniczna definicja źródeł prawdy żyje w **root `SOURCE-OF-TRUTH.md`**. Ten dokument **rozszerza** ją o hierarchię L0-L6 i przynależność dokumentacji. **Nie jest drugim SoT.**

## 2. Hierarchia źródeł prawdy

```text
L0  REALITY
L1  TELEMETRY / OBSERVATION
L2  RUNTIME / REGISTRY
L3  MISSION CONTROL
L4  GIT / DECLARATIVE SOURCE
L5  DOCUMENTATION
L6  LEGACY / HISTORY
```

## 3. Przynależność

| Kategoria | SoT |
|---|---|
| Source code | Git |
| Declarative deployment | Git |
| Runtime topology | Runtime/Registry |
| Runtime health | Telemetry/HELIOS |
| Dynamic memory | AIGON-X-FS / Knowledge Fabric |
| Agent session | Agent-local ephemeral state |
| Agent canonical memory | Runtime-managed Fabric |
| Architecture decision | ADR |
| Runtime truth | Runtime |
| Dokumentacja | Git (desired state) |

## 4. Dokumentacja a SoT

Dokumentacja jest na poziomie **L5** — poniżej Git (L4) i Runtime (L2).

Jeżeli dokument przeczy rzeczywistemu Runtime:

```text
DOCUMENT = STALE
```

Nie odwrotnie. Dokument nigdy nie może zmusić Runtime do zachowania określonego stanu.

## 5. Zasada "no second SoT"

Zgodnie z root SOURCE-OF-TRUTH.md:

```text
Nie tworzymy drugiego registry.
Nie tworzymy drugiej pamięci.
Nie tworzymy drugiego SoT.
```

Dokumentacja nie jest drugim SoT. Jest opisem.

## 6. Nieznane przynależności

Jeżeli czegoś nie wiadomo:

```text
UNKNOWN
```

Nie zakładaj szczegółów, których repo jeszcze nie potwierdza.

## Status

`STATUS: FOUNDATION PLACEHOLDER`
