# product

> Automatyzacja zarządzania produktem — backlog, wymagania, roadmapa, priorytetyzacja i śledzenie.

## 1. Purpose
Automatyzuje procesy zarządzania produktem: odkrywanie, definiowanie wymagań, zarządzanie backlogiem, priorytetyzację, roadmapę, akceptację i śledzenie wymagań.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Wymagania, backlog i roadmapa przechowywane w repozytorium są źródłem prawdy dla procesów produktowych.

## 4. Contains
Skrypty powłoki: acceptance.sh, backlog.sh, discovery.sh, prioritization.sh, requirements.sh, roadmap.sh, traceability.sh.

## 5. Does Not Contain
Nie zawiera samych wymagań ani pozycji backlogu — wyłącznie automatyzację procesów zarządzania produktem.

## 6. Dependencies
Wymaga narzędzi do zarządzania wymaganiami i backlogiem oraz dostępu do repozytorium produktu.

## 7. Consumers
Product managerowie, zespoły produktowe i procesy planowania wydań.

## 8. Synchronization
Skrypty synchronizowane z repozytorium przez standardowy mechanizm dystrybucji narzędzi automatyzacji.

## 9. Lifecycle
Ewoluują wraz z procesami produktowymi; wersjonowane w git, aktualizowane przy zmianie metodyk.

## 10. Security
Skrypty nie przechowują sekretów; dane produktowe podlegają kontroli dostępu repozytorium.

## 11. Recovery
W razie awarii skrypty można uruchomić ponownie; wymagania i backlog są odtwarzane z repozytorium.

## 12. Drift Detection
Rozbieżności między skryptami a wersją w repozytorium są wykrywane przez mechanizm certyfikacji.
