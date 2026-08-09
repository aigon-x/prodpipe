# integration

> Katalog testów integracyjnych — weryfikacja współpracy wielu komponentów z realnymi zależnościami.

## 1. Purpose
Przechowuje testy integracyjne, które weryfikują współpracę wielu komponentów platformy z realnymi zależnościami (bazy danych, kolejki, API).

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod testów). Wyniki wykonania to actual state (Runtime/CI). Testy są częścią desired state w repo.

## 4. Contains
Pliki testów integracyjnych, konfiguracje środowisk testowych, skrypty przygotowania danych testowych.

## 5. Does Not Contain
Nie zawiera testów jednostkowych (izolowanych), testów E2E pełnego stacku, danych produkcyjnych, sekretów.

## 6. Dependencies
Komponenty platformy pod testem, środowiska testowe (bazy, kolejki), `tests/fixtures`.

## 7. Consumers
CI/CD pipeline, deweloperzy, inżynierowie QA.

## 8. Synchronization
`CANONICAL` — kod testów jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy dodawaniu nowych integracji, zmienia się przy zmianach kontraktów między komponentami, wycofywany gdy integracja znika.

## 10. Security
Testy mogą dotykać środowisk testowych z danymi syntetycznymi. Nie powinny zawierać sekretów produkcyjnych.

## 11. Recovery
Odzyskiwane z git (checkout). Środowiska testowe odtwarzane z konfiguracji.

## 12. Drift Detection
Drift wykrywany przez CI: testy integracyjne nie przechodzą, kontrakty między komponentami się rozjeżdżają.

## Examples
`STATUS: UNDEFINED`
