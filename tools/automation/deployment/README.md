# deployment

> Automatyzacja wdrożeń — strategie blue-green, canary, infrastruktura i rollback.

## 1. Purpose
Automatyzuje procesy wdrożeniowe: wdrożenia standardowe, strategie blue-green i canary, zarządzanie infrastrukturą oraz wycofywanie zmian (rollback).

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Konfiguracje wdrożeń i definicje środowisk znajdują się w centralnych plikach konfiguracyjnych repozytorium.

## 4. Contains
Skrypty powłoki: blue-green.sh, canary.sh, deploy.sh, infrastructure.sh, rollback.sh.

## 5. Does Not Contain
Nie zawiera samych definicji infrastruktury ani manifestów wdrożeniowych — wyłącznie orkiestrację procesów wdrożeniowych.

## 6. Dependencies
Wymaga narzędzi do zarządzania infrastrukturą i wdrożeniami (np. konteneryzacja, orkiestracja) oraz dostępu do środowisk docelowych.

## 7. Consumers
Pipeline'y CI/CD, zespoły operacyjne i procesy wydawnicze.

## 8. Synchronization
Skrypty synchronizowane z repozytorium przez standardowy mechanizm dystrybucji narzędzi automatyzacji.

## 9. Lifecycle
Ewoluują wraz ze strategiami wdrożeniowymi; wersjonowane w git, aktualizowane przy zmianie procesów wydawniczych.

## 10. Security
Skrypty nie przechowują sekretów; dostęp do środowisk docelowych podlega kontroli dostępu i audytowi.

## 11. Recovery
Rollback jest realizowany przez dedykowany skrypt rollback.sh; stany wdrożeń są odtwarzane z artefaktów i logów.

## 12. Drift Detection
Rozbieżności między skryptami a wersją w repozytorium są wykrywane przez mechanizm certyfikacji.
