# security

> Automatyzacja bezpieczeństwa — zgodność, skanowanie zależności, analiza statyczna, modelowanie zagrożeń.

## 1. Purpose
Automatyzuje procesy bezpieczeństwa: zgodność, skanowanie zależności, testy penetracyjne, zarządzanie sekretami, analizę statyczną i modelowanie zagrożeń.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Polityki bezpieczeństwa i standardy zgodności zdefiniowane w repozytorium są źródłem prawdy dla procesów bezpieczeństwa.

## 4. Contains
Skrypty powłoki: compliance.sh, dependency-scan.sh, penetration.sh, secrets.sh, static-analysis.sh, threat-model.sh.

## 5. Does Not Contain
Nie zawiera samych raportów bezpieczeństwa ani narzędzi — wyłącznie orkiestrację procesów bezpieczeństwa.

## 6. Dependencies
Wymaga narzędzi bezpieczeństwa (skanery, analizatory) oraz dostępu do repozytorium i środowisk testowych.

## 7. Consumers
Zespoły bezpieczeństwa, procesy zgodności i bramki bezpieczeństwa przed wdrożeniem.

## 8. Synchronization
Skrypty synchronizowane z repozytorium przez standardowy mechanizm dystrybucji narzędzi automatyzacji.

## 9. Lifecycle
Ewoluują wraz z politykami bezpieczeństwa; wersjonowane w git, aktualizowane przy zmianie standardów.

## 10. Security
Skrypty nie przechowują sekretów; wyniki skanowania podlegają kontroli dostępu i audytowi.

## 11. Recovery
W razie awarii skrypty można uruchomić ponownie; raporty bezpieczeństwa są odtwarzane z artefaktów.

## 12. Drift Detection
Rozbieżności między skryptami a wersją w repozytorium są wykrywane przez mechanizm certyfikacji.
