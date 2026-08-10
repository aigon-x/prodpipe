# GIT-DOCUMENTATION-BOUNDARY — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — granica Git/Dokumentacja w fazie genesis.
> **Owner: UNASSIGNED**

## 1. Cel

Definiuje granicę między Git a Dokumentacją. Zapobiega myleniu wersjonowania z wyjaśnianiem.

## 2. Przynależność

```text
Git        = version history / source
Docs       = human/system explanation
Runtime    = actual state
Generated  = derived representation
```

## 3. Zasady

- **Git** przechowuje: kod, kontrakty, schematy, konfigurację deklaratywną, deployment, testy, polityki-as-code, dokumentację, manifesty, artefakty źródłowe.
- **Dokumentacja** opisuje i wyjaśnia to, co jest w Git i Runtime.
- **Git jest źródłem prawdy** dla dokumentacji (desired state).
- Dokumentacja **nie jest** drugim źródłem prawdy.

## 4. Co dokumentacja może

```text
describe
explain
specify
record decisions
define procedures
```

## 5. Czego dokumentacja nie może

```text
own Runtime state
override telemetry
override Registry
override SoT
become dynamic state
```

## 6. Wersjonowanie

Dokumentacja jest wersjonowana przez Git (jak kod). Zmiana dokumentacji przechodzi przez Git + verification.

## Status

`STATUS: FOUNDATION PLACEHOLDER`
