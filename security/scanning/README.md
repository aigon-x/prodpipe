# scanning

> Katalog konfiguracji skanowania bezpieczeństwa — definicje skanów podatności.

## 1. Purpose
Przechowuje konfiguracje skanowania bezpieczeństwa — definicje skanów podatności, konfiguracje skanerów i progi akceptacji.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (konfiguracje skanów). Wyniki skanów to actual state (GENERATED przez CI/Runtime).

## 4. Contains
Konfiguracje skanerów (np. Trivy, Snyk, SAST/DAST), definicje zakresów skanów, progi akceptacji.

## 5. Does Not Contain
Nie zawiera wyników skanów (te żyją w `artifacts/evidence`), sekretów, danych biznesowych.

## 6. Dependencies
`security/policies`, `security/threat-model`, `tests/security`.

## 7. Consumers
CI/CD pipeline, zespół bezpieczeństwa, zespół platformy.

## 8. Synchronization
`CANONICAL` — konfiguracje skanów są źródłem prawdy w git; wyniki to `GENERATED`.

## 9. Lifecycle
Powstaje przy definiowaniu nowych skanów, zmienia się przy zmianach zakresów, wycofywany gdy skan znika.

## 10. Security
Wysoka wrażliwość — konfiguracje skanów mogą ujawniać wektory ataku. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Odzyskiwane z git (checkout). Wyniki regenerowane przez skany.

## 12. Drift Detection
Drift wykrywany przez CI: skany wykrywają podatności powyżej progów akceptacji.

## Examples
`STATUS: UNDEFINED`
