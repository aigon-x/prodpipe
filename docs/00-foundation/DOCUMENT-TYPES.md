# DOCUMENT-TYPES — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — typy dokumentów w fazie genesis.
> **Owner: UNASSIGNED**

## 1. Cel

Definiuje kanoniczne typy dokumentów. Każdy dokument w repo musi mieć przypisany typ. Typ determinuje: Purpose, When to create, When NOT to create, Owner, Required sections, Lifecycle, Source of Truth.

## 2. Kanoniczne typy dokumentów

| Typ | Purpose | When to create | When NOT to create | Owner | Required sections | Lifecycle | Source of Truth |
|---|---|---|---|---|---|---|---|
| `README` | Opis katalogu/komponentu | Każdy katalog | — | Katalog owner | 12 sekcji | ACTIVE | Git |
| `SPEC` | Specyfikacja wymagań | Nowa funkcja/kontrakt | Gdy wystarczy ADR | Feature owner | Context, Requirements, Acceptance | DRAFT→ACTIVE→SUPERSEDED | Git |
| `PRD` | Product requirements | Nowy produkt/funkcja | Gdy wystarczy SPEC | Product owner | Problem, Users, Scope | DRAFT→ACTIVE→SUPERSEDED | Git |
| `RFC` | Propozycja techniczna | Nowa technologia/architektura | Gdy to decyzja (ADR) | Proposer | Problem, Proposal, Alternatives, Impact, Risks, Migration, Rollback, Evidence, Open Questions | PROPOSED→ACTIVE/REJECTED | Git |
| `DESIGN` | Projekt techniczny | Implementacja komponentu | Gdy wystarczy SPEC | Tech lead | Context, Design, Trade-offs | DRAFT→ACTIVE→SUPERSEDED | Git |
| `ARCHITECTURE` | Opis architektury | Architektura systemu | Gdy to decyzja (ADR) | Architect | Context, Components, Data flow, Trust boundaries | ACTIVE→STALE→SUPERSEDED | Git |
| `ADR` | Architektoniczna decyzja | Decyzja architektoniczna | Gdy to propozycja (RFC) | Decision owner | Title, Status, Context, Problem, Decision, Alternatives, Consequences, Evidence, SoT, Owner, Supersedes, Superseded By | PROPOSED→ACCEPTED→SUPERSEDED | Git |
| `POLICY` | Polityka | Reguła wiążąca | Gdy to procedura (SOP) | Policy owner | Scope, Rules, Enforcement | ACTIVE→SUPERSEDED | Git |
| `CONTRACT` | Kontrakt | Interfejs/API | Gdy to spec (SPEC) | Contract owner | Interface, Semantics, Versioning | ACTIVE→SUPERSEDED | Git |
| `SCHEMA` | Schemat danych | Struktura danych | Gdy to kontrakt (CONTRACT) | Data owner | Fields, Types, Constraints | ACTIVE→SUPERSEDED | Git |
| `RUNBOOK` | Procedura operacyjna | Operacja/awaria | Gdy to polityka (POLICY) | Ops owner | Trigger, Steps, Rollback | ACTIVE→SUPERSEDED | Git |
| `SOP` | Standardowa procedura | Powtarzalna operacja | Gdy to runbook (RUNBOOK) | Ops owner | Purpose, Steps, Owner | ACTIVE→SUPERSEDED | Git |
| `TEST-PLAN` | Plan testów | Nowa funkcja | Gdy to raport (TEST-REPORT) | QA owner | Scope, Cases, Criteria | DRAFT→ACTIVE→SUPERSEDED | Git |
| `TEST-REPORT` | Raport testów | Po wykonaniu testów | Gdy to plan (TEST-PLAN) | QA owner | Results, Failures, Coverage | ACTIVE | Git |
| `THREAT-MODEL` | Model zagrożeń | Nowy komponent | Gdy to audyt (INCIDENT) | Security owner | Assets, Threats, Mitigations | ACTIVE→SUPERSEDED | Git |
| `MIGRATION` | Plan migracji | Migracja | Gdy to decyzja (ADR) | Migration owner | From, To, Steps, Rollback | DRAFT→ACTIVE→COMPLETE | Git |
| `INCIDENT` | Zdarzenie | Awaria | Gdy to postmortem (POSTMORTEM) | On-call | Timeline, Impact, Resolution | ACTIVE→CLOSED | Git |
| `POSTMORTEM` | Analiza po awarii | Po incydencie | Gdy to raport (INCIDENT) | Incident owner | Summary, Root cause, Actions | ACTIVE→CLOSED | Git |
| `BASELINE` | Punkt odniesienia | Certyfikacja | Gdy to release (RELEASE-NOTES) | Release owner | Scope, Evidence, Status | ACTIVE→SUPERSEDED | Git |
| `RELEASE-NOTES` | Notatki wydania | Nowy release | Gdy to baseline (BASELINE) | Release owner | Changes, Migration, Rollback | ACTIVE | Git |
| `LIFECYCLE` | Konstytucja cyklu życia oprogramowania | Definicja faz/gate'ów/artefaktów | Gdy to polityka (POLICY) | Lifecycle owner | Phases, Gates, Artifacts, State machine, Traceability | ACTIVE→SUPERSEDED | Git |

## 3. Zasady

- Każdy dokument ma **dokładnie jeden** typ.
- Typ jest częścią metadata (front matter).
- Zmiana typu = nowy dokument (nie edycja).
- Dokument bez typu = `UNKNOWN` (validator wykrywa).

## 4. Mapowanie istniejących katalogów do typów

```text
CURRENT                         CANONICAL ROLE
────────────────────────────────────────────────
docs/architecture/              ARCHITECTURE
docs/decisions/                 ADR/RFC
docs/development/               DEVELOPMENT
docs/git/                       GIT
docs/operations/                OPERATIONS
docs/reference/                 REFERENCE
docs/security/                  SECURITY
docs/user/                      USER
governance/                     GOVERNANCE
root/*.md                       FOUNDATION / ENTRYPOINT / LEGACY?
```

## Status

`STATUS: FOUNDATION PLACEHOLDER`
