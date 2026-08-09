# quarantine

> Katalog kwarantanny — izolacja treści podejrzanych lub wycofanych.

## 1. Purpose
Przechowuje treści w kwarantannie — izolowane dokumenty, artefakty i konfiguracje podejrzane, wycofane lub wymagające przeglądu przed usunięciem.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kwarantanna). Kwarantanna jest częścią desired state w repo.

## 4. Contains
Treści w kwarantannie, artefakty wycofane, pliki wymagające przeglądu.

## 5. Does Not Contain
Nie zawiera aktywnego stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`STATUS: UNDEFINED`

## 7. Consumers
Zespół platformy, zespół bezpieczeństwa (przegląd).

## 8. Synchronization
`CANONICAL` — kwarantanna jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy izolacji treści, zmienia się przy przeglądach, wycofywany gdy treść usunięta lub przywrócona.

## 10. Security
Kwarantanna może zawierać podejrzane treści. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: treści w kwarantannie bez decyzji o losie.

## Examples
`STATUS: UNDEFINED`
