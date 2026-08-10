# RUNTIME-DOCUMENTATION-BOUNDARY — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — granica Runtime/Dokumentacja w fazie genesis.
> **Owner: UNASSIGNED**

## 1. Cel

Definiuje granicę między Runtime a Dokumentacją. Zasada nadrzędna:

```text
Runtime → truth
Documentation → explanation
```

## 2. Zasada

Jeżeli dokument twierdzi:

```text
Runtime has X
```

a Runtime mówi:

```text
Runtime has Y
```

to dokument:

```text
STALE
```

## 3. Przynależność

| Kategoria | SoT |
|---|---|
| Stan faktyczny | Runtime (actual state) |
| Discovery / topologia | Runtime |
| Health / tick | Runtime |
| Rejestry | Runtime |
| Evidence / capability | Runtime |
| Tożsamość nodów | Runtime |
| Stan deploymentu | Runtime |
| Opis systemu | Dokumentacja |

## 4. Zasady

- Dokumentacja **opisuje** Runtime, nie **posiada** go.
- Dokumentacja **nie nadpisuje** telemetrii, Registry ani SoT.
- Dokumentacja **nie staje się** stanem dynamicznym.
- Reconciliation: Git (desired) VS Runtime (actual) → **PASS / DRIFT**.

## 5. Drift

Wykrywanie rozjazdu między dokumentacją a Runtime jest zadaniem `tools/verify documentation` (adapter weryfikacyjny). Na tym etapie adapter nie istnieje — nie udawaj, że istnieje.

## Status

`STATUS: FOUNDATION PLACEHOLDER`
