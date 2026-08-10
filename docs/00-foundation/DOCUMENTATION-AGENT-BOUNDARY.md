# DOCUMENTATION-AGENT-BOUNDARY — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — granica Dokumentacja/Agenty w fazie genesis.
> **Owner: UNASSIGNED**

## 1. Cel

Definiuje granicę między Dokumentacją a Agentami. Zapobiega sytuacji, w której agenci stają się źródłem prawdy.

## 2. Co agenci mogą

```text
read
propose
generate
update through controlled workflow
```

## 3. Czego agenci NIE mogą

```text
be Source of Truth
silently modify canonical decisions
invent ADRs
invent policies
maintain private canonical documentation
```

## 4. Zasady

- Agent-generated documentation musi przechodzić przez **Git + verification**.
- Agenci nie mogą być źródłem prawdy.
- Agenci nie mogą po cichu modyfikować kanonicznych decyzji.
- Agenci nie mogą wymyślać ADR-ów ani polityk.
- Agenci nie mogą utrzymywać prywatnej kanonicznej dokumentacji.

## 5. Agent session vs canonical memory

```text
Agent session            → Agent-local ephemeral state
Agent canonical memory   → Runtime-managed Fabric
```

## Status

`STATUS: FOUNDATION PLACEHOLDER`
