# recovery

> Automatyzacja odzyskiwania — maksymalna dekompozycja problemów w procesach naprawczych.

## 1. Purpose
Automatyzuje procesy odzyskiwania i naprawy, w szczególności maksymalną dekompozycję problemów w celu izolowania i usuwania przyczyn awarii.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Procedury odzyskiwania i polityki naprawcze zdefiniowane w repozytorium są źródłem prawdy dla procesów naprawczych.

## 4. Contains
Skrypt powłoki: max-decomposition.sh.

## 5. Does Not Contain
Nie zawiera samych procedur odzyskiwania ani danych awarii — wyłącznie automatyzację dekompozycji problemów.

## 6. Dependencies
Wymaga dostępu do systemów objętych naprawą oraz narzędzi diagnostycznych.

## 7. Consumers
Zespoły operacyjne i procesy reagowania na awarie oraz odzyskiwania systemów.

## 8. Synchronization
Skrypt synchronizowany z repozytorium przez standardowy mechanizm dystrybucji narzędzi automatyzacji.

## 9. Lifecycle
Ewoluuje wraz z procedurami odzyskiwania; wersjonowany w git, aktualizowany przy zmianie procesów naprawczych.

## 10. Security
Skrypt nie przechowuje sekretów; dostęp do systemów objętych naprawą podlega kontroli dostępu.

## 11. Recovery
Sam proces odzyskiwania jest wspierany przez ten skrypt; stany systemów są odtwarzane zgodnie z procedurami.

## 12. Drift Detection
Rozbieżności między skryptem a wersją w repozytorium są wykrywane przez mechanizm certyfikacji.
