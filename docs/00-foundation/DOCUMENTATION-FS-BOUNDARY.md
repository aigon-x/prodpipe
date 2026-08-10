# DOCUMENTATION-FS-BOUNDARY — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — granica Dokumentacja/AIGON-X-FS w fazie genesis.
> **Owner: UNASSIGNED**

## 1. Cel

Definiuje granicę między Dokumentacją a AIGON-X-FS. Zapobiega zapisywaniu dynamicznej pamięci do Git/docs.

## 2. Przynależność

```text
Git
→ source / contracts

AIGON-X-FS
→ dynamic persistent data

Documentation
→ human/system-readable knowledge
```

## 3. Zasady

- **Git** przechowuje: źródła, kontrakty, dokumentację, konfigurację deklaratywną.
- **AIGON-X-FS** przechowuje: dynamiczne dane trwałe, pamięć agentów, dane użytkownika.
- **Dokumentacja** przechowuje: wiedzę czytelną dla ludzi/systemów.

## 4. Czego NIE robić

- Nie zapisuj danych użytkownika do Git/docs.
- Nie zapisuj dynamicznej pamięci do Git/docs.
- Nie zapisuj stanu Runtime do Git/docs.

## 5. Nieznane szczegóły

Szczegóły implementacji AIGON-X-FS pozostają `UNKNOWN`, jeżeli FS nie jest jeszcze zaimplementowany. Nie zakładaj szczegółów, których repo nie potwierdza.

## Status

`STATUS: FOUNDATION PLACEHOLDER`
