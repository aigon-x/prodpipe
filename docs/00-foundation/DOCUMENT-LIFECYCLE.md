# DOCUMENT-LIFECYCLE — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — lifecycle dokumentów w fazie genesis.
> **Owner: UNASSIGNED**

## 1. Cel

Definiuje statusy dokumentów i dozwolone przejścia między nimi. Zapobiega cichej wymianie dokumentów (`ACTIVE → silently replaced`).

## 2. Statusy dokumentów

```text
DRAFT
PROPOSED
ACTIVE
STALE
SUPERSEDED
DEPRECATED
ARCHIVED
```

## 3. Definicje statusów

| Status | Znaczenie | Kiedy |
|---|---|---|
| `DRAFT` | W przygotowaniu, niezatwierdzony | Dokument tworzony, przed review |
| `PROPOSED` | Zaproponowany, czeka na decyzję | RFC/ADR po złożeniu, przed akceptacją |
| `ACTIVE` | Obowiązujący, aktualny | Dokument zatwierdzony i używany |
| `STALE` | Nieaktualny, rozjazd z rzeczywistością | Dokument przeczy Runtime/SoT |
| `SUPERSEDED` | Zastąpiony przez inny dokument | Nowy dokument przejął rolę |
| `DEPRECATED` | Wycofany, ale jeszcze używany | Dokument oznaczony do wycofania |
| `ARCHIVED` | Zarchiwizowany, nieaktywny | Dokument przeniesiony do archiwum |

## 4. Dozwolone przejścia

```text
DRAFT ──────────────► PROPOSED ──────────────► ACTIVE
  │                      │                      │
  │                      ▼                      ▼
  └──► (odrzucony)   REJECTED               STALE
                                              │
                                              ▼
                                          SUPERSEDED
                                              │
                                              ▼
                                         DEPRECATED
                                              │
                                              ▼
                                          ARCHIVED
```

### Dozwolone przejścia (lista)

```text
DRAFT        → PROPOSED
DRAFT        → ARCHIVED        (porzucony)
PROPOSED     → ACTIVE          (zaakceptowany)
PROPOSED     → REJECTED        (odrzucony)
PROPOSED     → ARCHIVED        (porzucony)
ACTIVE       → STALE           (rozjazd z rzeczywistością)
ACTIVE       → SUPERSEDED      (zastąpiony)
ACTIVE       → DEPRECATED      (wycofany)
STALE        → ACTIVE          (zaktualizowany)
STALE        → SUPERSEDED      (zastąpiony)
STALE        → ARCHIVED        (zarchiwizowany)
SUPERSEDED   → DEPRECATED      (wycofany)
SUPERSEDED   → ARCHIVED        (zarchiwizowany)
DEPRECATED   → ARCHIVED        (zarchiwizowany)
```

### Zabronione przejścia

```text
ACTIVE → (silently replaced)   — NIGDY bez wskazania superseded_by
ACTIVE → ARCHIVED              — NIGDY bez przejścia przez SUPERSEDED/DEPRECATED
DRAFT  → ACTIVE                — NIGDY bez PROPOSED
```

## 5. Zasada supersession

Każde zastąpienie dokumentu musi wskazywać:

```text
superseded_by: <DOC-ID>
```

Dokument zastępujący musi wskazywać:

```text
supersedes: <DOC-ID>
```

## 6. Zasada "ACTIVE → silently replaced" jest zabroniona

Nie pozwól na:

```text
ACTIVE → silently replaced
```

Każde zastąpienie musi być jawne, z wskazaniem `superseded_by`.

## 7. Zasada "STALE"

Jeżeli dokument przeczy rzeczywistemu Runtime:

```text
DOCUMENT = STALE
```

Nie odwrotnie. Dokument nigdy nie może zmusić Runtime do zachowania określonego stanu.

## 8. Zasada "DELETE tylko gdy polityka pozwala"

Nigdy:

```text
rm document.md
```

bez sprawdzenia: references, consumers, supersession, history, owner.

Preferuj:

```text
SUPERSEDED → ARCHIVED
```

DELETE tylko jeżeli polityka pozwala.

## Status

`STATUS: FOUNDATION PLACEHOLDER`
