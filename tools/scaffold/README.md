# tools/scaffold

> Minimalny, deterministyczny scaffold — template + project manifest → nowy, izolowany projekt.
> Kontrakt: `contracts/scaffold/contract.md` (STATUS: DRAFT, zatwierdzony przez Suwerena).

## 1. Purpose
Tworzy nowy, izolowany projekt z template'a (Prod-ready) na podstawie project manifest.
Scaffold jest capability skeletona, NIE meta-systemem, NIE Runtime'em, NIE silnikiem wdrożeniowym.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER` — platform (CODEOWNERS).

## 3. Source of Truth
Git jest źródłem prawdy (desired state). Scaffold jest deterministyczny — wynik zależy tylko
od wejścia (manifest + template). Kontrakt: `contracts/scaffold/contract.md`.

## 4. Contains
- `scaffold.sh` — skrypt realizujący 7 kroków (LOAD → VALIDATE → RESOLVE → COPY → SUBSTITUTE → WRITE-MANIFEST → SELF-CHECK).
- `tests/test-scaffold.sh` — 8 testów kontraktu (poprawny manifest, brak pól, nieznany typ, zły root, kolizja, niedozwolona substytucja, template drift, determinizm).

## 5. Does Not Contain
Nie zawiera sekretów, runtime state, artefaktów, ani logiki Runtime'u/deploymentu.
Scaffold NIE zarządza scheduler/agents/mesh/runtime state/deployment/LLM/services.

## 6. Dependencies
- `config/canonical/registry.yaml` — walidacja `project.profile`.
- `VERSION` — walidacja `template.version`.
- `contracts/scaffold/contract.md` — kontrakt wejścia (8 pól manifestu, zamknięta lista 10 typów).
- Python3 + PyYAML — parsowanie manifestu i registry.yaml.

## 7. Consumers
UNIVERSALITY CERTIFICATION (FAZA B) — tworzenie 10 syntetycznych projektów (T01-T10).
Fresh Project Test — tworzenie prawdziwego nowego projektu.

## 8. Synchronization
Klasa: `CANONICAL` — scaffold jest źródłem prawdy w git. Template Drift Guard (P0 gate)
gwarantuje, że scaffold NIE modyfikuje template'a (TEMPLATE BEFORE == TEMPLATE AFTER).

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER` — scaffold jest częścią skeletona, certyfikowany przez verify.

## 10. Security
Klasyfikacja danych: SYSTEM. Scaffold kopiuje strukturę template'a BEZ sekretów
(`secrets/`, `*.env`, `*.pem`, `*.key`, `*.crt`, `*.p12`, `*.pfx`, `*.jks`).
Scaffold NIE tworzy sekretów, NIE konfiguruje sieci, NIE deployuje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania scaffold. Scaffold jest
deterministyczny — ponowne uruchomienie z tym samym manifestem daje identyczny wynik.

## 12. Drift Detection
Template Drift Guard (P0 gate): fingerprint (hash) template'a przed i po. TEMPLATE DRIFT = 0
= hashe identyczne. Scaffold kopiuje (nie przenosi) — template pozostaje nietknięty.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
