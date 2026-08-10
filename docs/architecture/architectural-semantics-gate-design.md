# ARCHITECTURAL SEMANTICS GATE — design doc

> Design doc — źródło specyfikacji dla implementacji ARCHITECTURAL SEMANTICS GATE.
> Status: DESIGN (do implementacji).
> Pochodzenie: wykryta luka semantyczna SEC D/A/R/C (patrz `docs/decisions/ARCHITECTURAL-KNOWLEDGE-GAP-SEC-DARC.md`).

## Cel

Zapobiec **silent architectural drift** wynikającemu z terminów, które wyglądają jak precyzyjne wymagania, ale nie mają formalnej definicji. Każdy termin używany przez system musi mieć kanoniczną definicję, źródło, właściciela i wersję. Jeżeli nie — `UNKNOWN_SEMANTICS`, a dla terminu krytycznego `GATE = FAIL`.

## Problem

Agent odkrył lukę semantyczną:

```text
DESIGN DOC → SEC D/A/R/C → brak definicji → brak źródła → brak historii → brak canonical meaning
```

Jeżeli agent wybierze znaczenie na podstawie zgadywania, za rok kolejny agent przeczyta `SEC-D` i uzna `D = Domain`, zaczynając implementować coś innego. To jest **silent architectural drift**.

## Co gate wykrywa

### 1. Terminy bez kanonicznej definicji

Każdy termin używany przez system musi mieć:

```text
TERM
CANONICAL DEFINITION
SOURCE
OWNER
VERSION
INTRODUCED_AT
LAST_CHANGED
RELATED_CONCEPTS
IMPLEMENTATION
TEST
DOCUMENTATION
```

Jeżeli brakuje któregoś z pól dla terminu krytycznego → `UNKNOWN_SEMANTICS` → `GATE = FAIL`.

### 2. Słowa-slogany

Gate wykrywa również słowa, które wyglądają jak precyzyjne wymagania, ale często nie mają formalnej definicji:

```text
"secure"
"trusted"
"safe"
"autonomous"
"critical"
"high risk"
"production ready"
"verified"
"canonical"
"resilient"
"sovereign"
```

Przykład: "production ready" — co to znaczy? Jeżeli nie ma `Production Ready = Gate 1 ∧ Gate 2 ∧ ... ∧ Gate N`, to jest tylko slogan.

## Epistemic Governance

FACT / INFERENCE / HYPOTHESIS / UNKNOWN **nie mogą się mieszać**. Każdy termin musi być oznaczony jednym z tych statusów epistemicznych:

| Status | Znaczenie |
|---|---|
| **FACT** | Zweryfikowany, ma źródło i dowód |
| **INFERENCE** | Wyprowadzony z faktów, ale nie bezpośrednio zaobserwowany |
| **HYPOTHESIS** | Proponowany, niezweryfikowany |
| **UNKNOWN** | Nieznany — wymaga decyzji właściciela |

## Rejestr terminów (glossary)

Gate opiera się na **rejestrze terminów** (glossary), który jest źródłem prawdy dla definicji. Format wpisu:

```yaml
term: SEC-D
canonical_definition: Detection — wykrywanie intruzji, anomalii, kompromitacji
source: docs/decisions/ARCHITECTURAL-KNOWLEDGE-GAP-SEC-DARC.md
owner: sovereign
version: 1
introduced_at: 2026-08-10
last_changed: 2026-08-10
related_concepts: [SEC-A, SEC-R, SEC-C]
implementation: tools/verify/security/drills.sh
test: tools/verify/tests/test-security-drills.sh
documentation: docs/security/
epistemic_status: HYPOTHESIS   # FACT | INFERENCE | HYPOTHESIS | UNKNOWN
```

## Check ID

| ID | Check | Co mierzy |
|---|---|---|
| SEM-001 | Każdy termin krytyczny ma wpis w glossary z canonical_definition | kompletność definicji |
| SEM-002 | Każdy termin krytyczny ma source (skąd pochodzi) | źródło |
| SEM-003 | Każdy termin krytyczny ma owner | właściciel |
| SEM-004 | Każdy termin krytyczny ma version | wersjonowanie |
| SEM-005 | Każdy termin krytyczny ma epistemic_status (FACT/INFERENCE/HYPOTHESIS/UNKNOWN) | epistemic governance |
| SEM-006 | Słowa-slogany ("production ready", "secure", "trusted" itd.) mają formalną definicję (nie są gołe) | wykrywanie sloganów |
| SEM-007 | Termin z epistemic_status=UNKNOWN dla terminu krytycznego → FAIL (wymaga decyzji właściciela) | blokada niepewności |

## Fail-closed

Gate jest **fail-closed**: brak glossary, brak wpisu dla terminu krytycznego, brak epistemic_status → FAIL (BLOCKING). Nie ma "skip" dla niepewności — niepewność jest jawnie oznaczona i wymaga decyzji.

## Konfiguracja

- Lista terminów krytycznych — z configu (registry.yaml), nie hardcode.
- Lista słów-sloganów — z configu.
- Próg: termin krytyczny bez definicji → FAIL; termin niekrytyczny bez definicji → WARN.

## Integracja

- Moduł verify: `tools/verify/architecture/semantics.sh` (lub wg konwencji repo).
- Rejestracja w `gates.yaml` + `gen-profiles.sh`.
- Testy: `tools/verify/tests/test-semantics.sh`.
- Dokumentacja: ten design doc + wpis w glossary.

## Kolejność wdrożenia

1. Glossary (rejestr terminów) — źródło prawdy.
2. Moduł verify (SEM-001..007) — fail-closed.
3. Rejestracja w gates.yaml + gen-profiles.sh.
4. Testy.
5. Wpis SEC D/A/R/C do glossary jako HYPOTHESIS (z odwołaniem do AKG).
