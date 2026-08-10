# Contract: Scaffold

> **STATUS: DRAFT** — kontrakt minimalnego, deterministycznego scaffold jako capability skeletona.
> Faza A (SCAFFOLD CONTRACT) w ramach UNIVERSALITY CERTIFICATION.

## 1. Cel

Zdefiniować minimalny, deterministyczny **scaffold** — cienki adapter, który tworzy nowy projekt
z template'a (Prod-ready) na podstawie **project manifest**. Scaffold jest capability skeletona,
NIE meta-systemem, NIE Runtime'em, NIE silnikiem wdrożeniowym.

Scaffold odpowiada na jedno pytanie: **"jak z template'a + manifestu powstaje nowy, izolowany projekt?"**

## 2. Zakres (co scaffold ROBI)

Scaffold wykonuje **jedną, deterministyczną transformację**:

```
template (Prod-ready) + project manifest → nowy projekt (izolowany)
```

Konkretnie:
- **Czyta** project manifest (wejście).
- **Waliduje** manifest względem kontraktu (fail-closed — nieznane pole = błąd).
- **Kopiuje** strukturę template'a do project root (bez sekretów, bez artefaktów).
- **Podstawia** wartości manifestu w plikach template'a (project name, identity, config).
- **Zapisuje** project manifest w nowym projekcie (traceability).
- **Weryfikuje** że nowy projekt jest kompletny i izolowany (self-check).

## 3. Kontrakt wejścia — Project Manifest

Manifest to jedyne wejście scaffold. Format: YAML. Pola (wszystkie wymagane):

| Pole | Typ | Opis | Przykład |
|------|-----|------|----------|
| `schema_version` | int | Wersja kontraktu manifestu | `1` |
| `project.identity` | string | Unikalny identyfikator projektu (slug) | `t01-minimal` |
| `project.type` | string | Typ projektu (z listy typów poniżej) | `minimal` |
| `project.profile` | string | Profil config (z registry.yaml) | `fast` |
| `project.name` | string | Nazwa projektu (display) | `T01 Minimal` |
| `project.config` | map | Konfiguracja projektu (override) | `{}` |
| `project.root` | string | Ścieżka docelowa nowego projektu | `./out/t01` |
| `template.version` | string | Wersja template'a (z VERSION) | `0.1.0` |

### Typy projektów (project.type)
Lista typów jest **zamknięta** i zdefiniowana w tym kontrakcie (nie w taxonomy.yaml —
taxonomy.yaml definiuje wymiary doskonałości QI, nie typy projektów). Typy odpowiadają
syntetycznym projektom UNIVERSALITY CERTIFICATION (T01-T10):

| Typ | Opis | Projekt testowy |
|-----|------|-----------------|
| `minimal` | Minimalny projekt (skeleton) | T01 |
| `cli` | Narzędzie CLI | T02 |
| `rust-backend` | Backend w Rust | T03 |
| `python-service` | Serwis w Python | T04 |
| `web` | Aplikacja web | T05 |
| `ai` | Serwis AI/ML | T06 |
| `distributed` | System rozproszony | T07 |
| `data` | Serwis danych | T08 |
| `multi-service` | System wieloserwisowy | T09 |
| `filesystem` | Serwis filesystem | T10 |

### Zasady walidacji manifestu (fail-closed)
- Nieznane pole = **błąd** (nie ignoruj). Scaffold nie rozszerza kontraktu.
- Brakujące wymagane pole = **błąd**.
- `project.identity` musi być unikalne (slug, lowercase, `[a-z0-9-]`).
- `project.type` musi być jedną z zamkniętej listy typów (powyżej).
- `project.profile` musi istnieć w registry.yaml.
- `template.version` musi zgadzać się z wersją template'a (VERSION).

## 4. Zachowanie scaffold (determinizm)

Scaffold jest **deterministyczny**: ten sam manifest + ten sam template → identyczny wynik
(poza timestampami/identyfikatorami, które są jawnie oznaczone jako non-deterministic).

### Sekwencja (kroki)
1. **LOAD** — wczytaj manifest.
2. **VALIDATE** — waliduj manifest (fail-closed).
3. **RESOLVE** — rozwiąż template (ścieżka, wersja).
4. **COPY** — skopiuj strukturę template'a do project root.
5. **SUBSTITUTE** — podstaw wartości manifestu w plikach.
6. **WRITE-MANIFEST** — zapisz manifest w nowym projekcie.
7. **SELF-CHECK** — zweryfikuj kompletność i izolację nowego projektu.

### Determinizm
- Kopiowanie: tylko pliki template'a, bez sekretów (`secrets/`, `*.env`), bez artefaktów
  (`artifacts/`, `reports/`), bez `.git/`.
- Substytucja: tylko jawnie oznaczone tokeny (np. `{{project.name}}`), nigdy regex na całym pliku.
- Wynik: identyczny dla identycznego wejścia.

## 5. Czego scaffold NIE robi (poza zakresem)

Scaffold **NIE**:
- Nie implementuje Runtime'u, deploymentu, ani biznesowej logiki.
- Nie jest meta-systemem — nie zarządza innymi scaffoldami.
- Nie uruchamia gate'ów verify na nowym projekcie (to robi certyfikacja, nie scaffold).
- Nie tworzy sekretów, nie konfiguruje sieci, nie deployuje.
- Nie modyfikuje template'a (TEMPLATE DRIFT = 0).
- Nie rozszerza kontraktu — nieznane pole manifestu = błąd.

## 6. Integracja z istniejącymi konwencjami

Scaffold wpisuje się w istniejące warstwy skeletona:

| Warstwa | Rola | Integracja scaffold |
|---------|------|---------------------|
| **Verify engine** (`tools/verify/`) | Certyfikuje repo | Scaffold jest certyfikowany przez verify (moduł `scaffold`), nie odwrotnie |
| **Config Plane** (`config/canonical/registry.yaml`) | L0-L7 config | Scaffold czyta `project.profile` z registry.yaml |
| **gates.yaml** | Definicje modułów | Scaffold dodaje moduł `scaffold` (skrypt `scaffold/scaffold.sh`) |
| **Taxonomy** (`config/canonical/taxonomy.yaml`) | Wymiary doskonałości QI | Scaffold NIE zależy od taxonomy (typy projektów są w tym kontrakcie) |
| **Contracts** (`contracts/`) | Umowy | Scaffold jest kontraktem (ten dokument) |
| **VERSION** | Wersja template'a | Scaffold waliduje `template.version` względem VERSION |

## 7. Warunek TEMPLATE DRIFT = 0

**Najważniejszy warunek certyfikacji:** projekt testowy NIE może modyfikować template'a.

- Scaffold kopiuje (nie przenosi) — template pozostaje nietknięty.
- Po utworzeniu 10 projektów testowych (T01-T10), template musi być **identyczny** z przed.
- Weryfikacja: fingerprint (hash) template'a przed i po. **TEMPLATE DRIFT = 0** = hashe identyczne.

## 8. Status i dalsze kroki

- **STATUS: DRAFT** — kontrakt do zatwierdzenia przez Suwerena.
- Po zatwierdzeniu → **implementacja scaffold** (FAZA A impl) → **testy** → **UNIVERSALITY CERTIFICATION** (FAZA B).

## Source of Truth
Git (desired state). Scaffold jest deterministyczny — wynik zależy tylko od wejścia (manifest + template).

## Status
**STATUS: DRAFT** — kontrakt zaprojektowany, czeka na zatwierdzenie przed implementacją.
