# SECURITY.md

## AIGON Production Platform — Polityka bezpieczeństwa

---

## 1. Zasada nadrzędna

**Nigdy nie zapisuj sekretów w Git.**

Repo zawiera wyłącznie:

```text
schemas
templates
references
rotation policies
```

Production secrets są **zewnętrzne** (Secret Manager / bootstrap mechanism).

---

## 2. Klasyfikacja danych

Rozdzielamy:

```text
SYSTEM DATA
TENANT DATA
USER DATA
SESSION DATA
CACHE
TEMPORARY ARTIFACTS
```

User data ma własne: owner, tenant, retention, encryption, backup, restore,
audit. **Nie mieszaj user data z runtime state.**

---

## 3. Co jest zabronione w repo

- sekrety (klucze, hasła, tokeny, certyfikaty prywatne)
- runtime state
- dane użytkowników
- dane tenantów
- cache
- logi
- build artifacts (binaria)

---

## 4. Granice

- `business` nie implementuje ponownie runtime/scheduler/memory/knowledge/
  governance/distributed filesystem/agent registry.
- `business` nie ma dostępu do internals runtime ani AIGON-X-FS.
- `dashboard` nie ma dostępu do internals bazy danych.
- `agent` nie mutuje canonical state ani governance.

---

## 5. Raportowanie podatności

STATUS: UNDEFINED — kanał raportowania podatności do ustalenia przez
właściciela platformy.

---

## 6. Scanning

CI uruchamia scanning (patrz `.github/workflows/security.yml`):

- secret scanning
- dependency scanning
- container image scanning (SBOM, CVE)
- SAST
- policy-as-code validation

---

## 7. Rotacja sekretów

STATUS: UNDEFINED — polityka rotacji do ustalenia. Repo zawiera tylko
schematy i szablony polityk, nigdy wartości.
