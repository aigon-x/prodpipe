# helm

> Katalog dla chartów Helm AIGON Production Platform — pakowanie i wdrażanie aplikacji.

## 1. Purpose
Przechowuje charty Helm — spakowane definicje wdrożeń aplikacji wraz z szablonami i wartościami.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla chartów Helm. Runtime odzwierciedla actual state wdrożonych release'ów.

## 4. Contains
Charty Helm, szablony, wartości (values), definicje release'ów.

## 5. Does Not Contain
Nie zawiera obrazów binarnych, sekretów ani runtime state.

## 6. Dependencies
Zależy od deployment/images, deployment/manifests, deployment/rings.

## 7. Consumers
Pipeline wdrożeniowy, orkiestrator, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — charty Helm są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i referencje.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania chartów Helm.

## 12. Drift Detection
Wykrywanie rozjazdu między chartami (git) a faktycznie wdrożonymi release'ami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
