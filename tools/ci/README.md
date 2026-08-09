# ci

> Katalog konfiguracji CI/CD — definicje pipeline'ów ciągłej integracji.

## 1. Purpose
Przechowuje konfiguracje CI/CD — definicje pipeline'ów ciągłej integracji, ciągłego dostarczania i wdrożeń.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (konfiguracje CI). Konfiguracje są częścią desired state w repo.

## 4. Contains
Definicje pipeline'ów (np. GitHub Actions, GitLab CI), konfiguracje buildów, kroki wdrożeń.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`tools/scripts`, `tools/validation`, `tests/`.

## 7. Consumers
CI/CD runner, zespół platformy, deweloperzy.

## 8. Synchronization
`CANONICAL` — konfiguracje CI są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu pipeline'ów, zmienia się przy zmianach procesów, wycofywany gdy pipeline znika.

## 10. Security
Konfiguracje CI mogą zawierać referencje do sekretów (nie same sekrety). Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez CI: pipeline'y nie przechodzą, konfiguracje odbiegają od faktycznych procesów.

## Examples
`STATUS: UNDEFINED`
