# manifests

> Katalog dla manifestów wdrożeniowych AIGON Production Platform — deklaratywne definicje wdrożeń.

## 1. Purpose
Przechowuje manifesty wdrożeniowe — deklaratywne definicje usług, kontenerów i ich konfiguracji.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla manifestów. Runtime odzwierciedla actual state wdrożonych usług.

## 4. Contains
Manifesty wdrożeniowe, definicje usług, konfiguracja kontenerów.

## 5. Does Not Contain
Nie zawiera obrazów binarnych, sekretów ani runtime state.

## 6. Dependencies
Zależy od deployment/images, deployment/rings, deployment/profiles.

## 7. Consumers
Pipeline wdrożeniowy, orkiestrator, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — manifesty są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i referencje.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania manifestów.

## 12. Drift Detection
Wykrywanie rozjazdu między manifestami (git) a faktycznie wdrożonymi usługami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
