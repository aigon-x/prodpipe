# README TEMPLATE — AIGON Production Platform

Każdy katalog w `/opt/Prod-ready/` MUSI mieć `README.md` z DOKŁADNIE tymi 12 sekcjami, w tej kolejności. Użyj `STATUS: UNDEFINED` tam, gdzie nie znasz odpowiedzi — NIGDY nie zmyślaj faktów. Jeśli katalog nie może odpowiedzieć na pytanie "kto jest właścicielem / gdzie jest prawda / kto zmienia / kto czyta / co się synchronizuje / jak wykryć drift / jak odzyskać" → wpisz `STATUS: ARCHITECTURAL GAP`.

---

# `<NAZWA KATALOGU>`

> Krótki opis (1-2 zdania) celu tego katalogu w architekturze AIGON Production Platform.

## 1. Purpose
Cel katalogu. Co tu żyje i dlaczego istnieje.

## 2. Owner
Właściciel domeny (zgodnie z CODEOWNERS / OWNERSHIP.md). Jeśli nieznany → `STATUS: UNDEFINED`.

## 3. Source of Truth
Gdzie jest źródło prawdy dla zawartości tego katalogu. Zasada: **Git = desired state, Runtime = actual state**. Jeśli nie da się wskazać → `STATUS: ARCHITECTURAL GAP`.

## 4. Contains
Co ten katalog ZAWIERA (lista typów plików / artefaktów).

## 5. Does Not Contain
Czego ten katalog NIE zawiera (granice — np. brak runtime state, brak sekretów, brak drugiego SoT).

## 6. Dependencies
Od czego ten katalog zależy (inne katalogi / systemy / kontrakty).

## 7. Consumers
Kto czyta / konsumuje zawartość tego katalogu.

## 8. Synchronization
Klasa synchronizacji: `CANONICAL` / `REPLICATED` / `GENERATED` / `CACHE` / `SESSION` / `EPHEMERAL`. Jak i kiedy się synchronizuje.

## 9. Lifecycle
Cykl życia: jak powstaje, jak się zmienia, jak jest wycofywany.

## 10. Security
Wymagania bezpieczeństwa: klasyfikacja danych, zakazy, granice.

## 11. Recovery
Jak odzyskać zawartość po awarii / utracie.

## 12. Drift Detection
Jak wykryć, że zawartość odbiega od stanu pożądanego (desired state).

## Examples
Przykłady użycia / przykładowe pliki (jeśli znane; w przeciwnym razie `STATUS: UNDEFINED`).
