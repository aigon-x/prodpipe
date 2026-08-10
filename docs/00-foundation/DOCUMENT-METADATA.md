# DOCUMENT-METADATA — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — kontrakt metadata dokumentów w fazie genesis.
> **Owner: UNASSIGNED**

## 1. Cel

Definiuje standardowy front matter dla dokumentów. Metadata umożliwia automatyczną walidację, indeksowanie i wykrywanie driftu.

## 2. Preferowany model front matter

```yaml
---
id: DOC-XXXX
type: architecture
title: ...
status: active
owner: ...
source_of_truth: ...
created: ...
updated: ...
version: ...
supersedes: ...
superseded_by: ...
consumers: []
---
```

## 3. Pola

| Pole | Wymagane | Typ | Opis |
|---|---|---|---|
| `id` | TAK | string | Niezmienny, unikalny identyfikator dokumentu |
| `type` | TAK | enum | Jeden z kanonicznych typów (DOCUMENT-TYPES) |
| `title` | TAK | string | Tytuł dokumentu |
| `status` | TAK | enum | Jeden z lifecycle statusów (DOCUMENT-LIFECYCLE) |
| `owner` | TAK | string | Właściciel dokumentu (lub `UNASSIGNED`) |
| `source_of_truth` | TAK | string | Źródło prawdy (Git/Runtime/Registry/...) |
| `created` | TAK | date | Data utworzenia |
| `updated` | NIE | date | Data ostatniej aktualizacji |
| `version` | NIE | string | Wersja dokumentu |
| `supersedes` | NIE | string | ID dokumentu zastępowanego |
| `superseded_by` | NIE | string | ID dokumentu zastępującego |
| `consumers` | NIE | list | Konsumenci dokumentu |

## 4. Zasady

- **Nie wymagaj ręcznego wpisywania pól, które mogą być generowane** (np. `updated`, `version`).
- **Nie używaj daty jako głównego identyfikatora** — ID jest niezmienne i niezależne od daty.
- `id` jest: immutable, unique, never reused.
- Zmiana tytułu **nie zmienia** ID.
- `owner` nieznany → `UNASSIGNED` (nie wymyślaj osoby).
- `source_of_truth` nieznany → `UNKNOWN`.

## 5. Dokumenty bez front matter

Dokumenty bez front matter są klasyfikowane jako `UNKNOWN` przez validator. Nie blokują, ale są raportowane jako WARNING (do uzupełnienia w DOC-RECONCILIATION).

## 6. Dokumenty root

Dokumenty root (ARCHITECTURE.md, SOURCE-OF-TRUTH.md, OWNERSHIP.md, MIGRATION.md, RECOVERY.md, DEPLOYMENT.md, SECURITY.md) są istniejącą pracą Foundation. Ich metadata jest uzupełniana w DOC-RECONCILIATION, nie w tym etapie.

## Status

`STATUS: FOUNDATION PLACEHOLDER`
