# images

> Katalog dla definicji obrazów kontenerowych AIGON Production Platform — immutable image digests, bez `:latest` w produkcji.

## 1. Purpose
Definiuje obrazy kontenerowe i ich niezmienne digesty (immutable image digests). W produkcji NIGDY nie używa się `:latest`.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji obrazów i digestów. Runtime odzwierciedla faktycznie uruchomione obrazy.

## 4. Contains
Definicje obrazów, niezmienne digesty, listy obrazów per usługa, polityki wersjonowania obrazów.

## 5. Does Not Contain
Nie zawiera binarnych obrazów (te żyją w rejestrze), sekretów ani runtime state.

## 6. Dependencies
Zależy od rejestru obrazów oraz deployment/rings, deployment/profiles.

## 7. Consumers
Pipeline wdrożeniowy, orkiestrator, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — definicje obrazów i digestów są źródłem prawdy w git.

## 9. Lifecycle
Obrazy są niezmienne (immutable); nowe wersje tworzą nowe digesty, stare są wycofywane.

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git; wymagane skanowanie obrazów pod kątem podatności.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania definicji obrazów.

## 12. Drift Detection
Wykrywanie rozjazdu między zdefiniowanymi digestami (git) a faktycznie uruchomionymi obrazami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
