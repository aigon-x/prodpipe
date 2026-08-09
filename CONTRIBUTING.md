# CONTRIBUTING.md

## AIGON Production Platform — Zasady współpracy

Ten dokument opisuje, jak wprowadzać zmiany do kanonicznego repozytorium
produkcyjnego AIGON. Jest to **repo architektury**, nie zwykły kod.

---

## 1. Zasada nadrzędna

> **Git mówi, co zbudowaliśmy. Runtime mówi, co naprawdę istnieje.**

Git przechowuje: kod, kontrakty, schematy, deklaratywną konfigurację,
deployment definitions, testy, polityki jako kod, dokumentację, manifesty,
source artifacts.

Runtime przechowuje: rzeczywisty stan, discovery, topology, health, tick,
aktualne registry, faktycznie działające komponenty, runtime evidence,
aktualne capabilities, faktyczne node identity, faktyczne deployment state.

**Nie wrzucaj runtime state do Gita. Nie rób z AIGON-X-FS kolejnego repo.**

---

## 2. Model branchy

Nie używamy `develop`. Używamy:

```text
main
 ├── feature/...
 ├── fix/...
 ├── migration/...
 ├── security/...
 └── release/...
```

`main` jest **protected** — nie commitujemy bezpośrednio na `main`.

### Merge do `main` (PR)

```text
PR
 ↓
Build
 ↓
Unit
 ↓
Integration
 ↓
Regression
 ↓
SOT
 ↓
Drift
 ↓
Feature
 ↓
Three Witnesses
 ↓
HELIOS
 ↓
BASELINE
 ↓
MERGE
```

Każdy merge przechodzi przez pełny łańcuch walidacji. Nie ma skrótów.

---

## 3. Granice architektury (CI odrzuca)

CI **odrzuca** PR, który narusza:

```text
agent → canonical state
agent → governance mutation
business → runtime internals
business → aigon-x-fs internals
dashboard → database internals
node config → global truth
hardcoded IP
hardcoded hostname
hardcoded node count
hardcoded kernel count
duplicate registry
duplicate SoT
secret in repository
latest image
unowned crate
unowned config
```

---

## 4. Własność

Każda domena ma dokładnie jednego właściciela (patrz `OWNERSHIP.md` i
`CODEOWNERS`). Zmiany w domenie wymagają review właściciela.

---

## 5. Source of Truth

Każda domena ma dokładnie jeden Source of Truth (patrz `SOURCE-OF-TRUTH.md`).
Nie twórz drugiego SoT. Nie twórz drugiego registry. Nie twórz drugiej pamięci.

---

## 6. Sekrety

**Nigdy nie zapisuj sekretów w Git.** Repo zawiera tylko schematy, szablony,
referencje i polityki rotacji. Production secrets są zewnętrzne.

---

## 7. Commit message

Format:

```text
<type>(<scope>): <opis>

<dlaczego — kontekst, nie tylko co>
```

Typy: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `security`,
`migration`, `release`, `genesis`.

---

## 8. Definition of Done

Zmiana jest gotowa tylko jeśli:

- [ ] przechodzi build
- [ ] przechodzi unit + integration + regression
- [ ] przechodzi SOT check
- [ ] przechodzi drift check
- [ ] nie narusza granic architektury
- [ ] nie zawiera sekretów
- [ ] ma właściciela
- [ ] ma jasny Source of Truth
- [ ] nie tworzy drugiego SoT / registry / pamięci
