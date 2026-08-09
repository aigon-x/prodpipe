# profiles

> Katalog dla profili compose (compose profiles) AIGON Production Platform — selektywne uruchamianie usług.

## 1. Purpose
Definiuje profile compose — selektywne grupy usług uruchamiane w zależności od kontekstu (dev, prod, monitoring itd.).

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla profili. Runtime odzwierciedla actual state uruchomionych usług.

## 4. Contains
Definicje profili compose, mapowanie usług do profili, konfiguracja profili.

## 5. Does Not Contain
Nie zawiera obrazów binarnych, sekretów ani runtime state.

## 6. Dependencies
Zależy od deployment/manifests, deployment/images.

## 7. Consumers
Pipeline wdrożeniowy, orkiestrator, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — definicje profili są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i polityki.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania profili.

## 12. Drift Detection
Wykrywanie rozjazdu między zdefiniowanymi profilami (git) a faktycznie uruchomionymi usługami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
