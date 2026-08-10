# DOCUMENTATION-CONSTITUTION — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — konstytucja dokumentacyjna w fazie genesis.
> **Owner: UNASSIGNED**

## 1. Zasada nadrzędna

**Documentation ≠ Source of Truth.**

Dokumentacja **opisuje**, **wyjaśnia**, **specyfikuje**, **rejestruje decyzje** i **definiuje procedury**. Dokumentacja **nie posiada** stanu Runtime, **nie nadpisuje** telemetrii, **nie nadpisuje** Registry, **nie nadpisuje** Source of Truth i **nie staje się** stanem dynamicznym.

## 2. Hierarchia źródeł prawdy

Obowiązuje hierarchia:

```text
L0  REALITY
L1  TELEMETRY / OBSERVATION
L2  RUNTIME / REGISTRY
L3  MISSION CONTROL
L4  GIT / DECLARATIVE SOURCE
L5  DOCUMENTATION
L6  LEGACY / HISTORY
```

Jeżeli dokument przeczy rzeczywistemu Runtime:

```text
DOCUMENT = STALE
```

Nie odwrotnie. Dokument nigdy nie może zmusić Runtime do zachowania określonego stanu.

## 3. Co dokumentacja ROBI

Dokumentacja:

```text
describes      — opisuje system
explains       — wyjaśnia dlaczego
specifies      — specyfikuje kontrakty
records        — rejestruje decyzje (ADR)
defines        — definiuje procedury
```

## 4. Czego dokumentacja NIE ROBI

Dokumentacja NIE:

```text
owns Runtime state          — nie posiada stanu Runtime
overrides telemetry         — nie nadpisuje obserwacji
overrides Registry          — nie nadpisuje rejestru
overrides SoT               — nie nadpisuje źródła prawdy
becomes dynamic state       — nie staje się stanem dynamicznym
```

## 5. Zasada "Search before create"

Przed utworzeniem jakiegokolwiek dokumentu:

```text
Problem
↓
Existing document search
↓
Reuse?
↓
Modify / Create
↓
Evidence
↓
Validation
↓
Review
↓
Commit
```

Jeżeli nie wiadomo po co dokument istnieje:

```text
DO NOT CREATE
```

## 6. Zasada "Nie twórz dokumentacyjnego legacy"

Nie twórz dokumentów o nazwach typu:

```text
ARCHITECTURE_FINAL.md
ARCHITECTURE_FINAL2.md
ARCHITECTURE_NEW.md
ARCHITECTURE_V2.md
README_REAL.md
README_ACTUAL.md
DESIGN_NEW.md
```

Każdy dokument musi mieć: Purpose, Owner, Status, Source of Truth, Consumers, Lifecycle.

## 7. Zasada "Nie naprawiaj architektury przez dołożenie drugiej architektury"

Nie twórz canonical tree równolegle do istniejącego tree. Najpierw udowodnij, że istniejące tree nie może pełnić tej funkcji.

## 8. Zasada "Nie twórz drugiego systemu verification"

Dokumentacja jest weryfikowana przez **jeden** validator: `tools/verify documentation`. Nie twórz drugiego systemu verification.

## 9. Zasada "Nie twórz drugiego secret scanner"

Sekrety w dokumentacji są skanowane przez istniejący `secret-scan.sh`. Nie twórz drugiego secret scanner.

## 10. Zasada "Nie twórz AI Documentation Judge"

Nie buduj oceny jakości języka przez LLM. To byłoby naruszenie moratorium i kolejny meta-system.

## 11. Zasada "Nie twórz meta-systemu bez potrzeby"

Dokumentacja ma być: discoverable, typed, owned, versioned, verifiable, traceable, recoverable, non-authoritative over runtime.

## 12. Zasada "Dokumentacja jest generowalna"

Docelowo dokumentacja ma być generowana z:

```text
CODE
  ↓
CONTRACTS
  ↓
RUNTIME
  ↓
EVIDENCE
  ↓
GENERATED DOCUMENTATION
```

a nie:

```text
HUMAN WRITES DOC
        ↓
HUMAN REMEMBERS DOC
        ↓
CODE DRIFTS
        ↓
LEGACY
```

## Status

`STATUS: FOUNDATION PLACEHOLDER`
