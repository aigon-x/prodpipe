# legacy

> Katalog archiwum legacy — archiwizacja treści z poprzednich systemów.

## 1. Purpose
Przechowuje zarchiwizowane treści legacy — dokumenty, artefakty i konfiguracje z poprzednich systemów i wersji platformy.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (archiwum). Archiwum jest częścią desired state w repo.

## 4. Contains
Zarchiwizowane treści legacy, stare dokumenty, artefakty, konfiguracje.

## 5. Does Not Contain
Nie zawiera aktywnego stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`STATUS: UNDEFINED`

## 7. Consumers
Audytorzy, zespół platformy (przegląd historyczny).

## 8. Synchronization
`CANONICAL` — archiwum jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy archiwizacji treści legacy, zmienia się przy nowych archiwizacjach, wycofywany gdy treść trwale usunięta.

## 10. Security
Archiwum legacy może zawierać historyczne dane wrażliwe. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: aktywne treści nie powinny znajdować się w archiwum legacy.

## Examples
`STATUS: UNDEFINED`
