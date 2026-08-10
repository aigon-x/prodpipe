# design

> Automatyzacja architektury i projektowania — dokumenty projektowe, kontrakty, analiza wpływu zmian.

## 1. Purpose
Automatyzuje procesy projektowe i architektoniczne: tworzenie dokumentów projektowych, definiowanie kontraktów, analizę wpływu zmian, modelowanie danych oraz zarządzanie długiem technicznym.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Dokumenty projektowe, definicje kontraktów i modele danych przechowywane w repozytorium są źródłem prawdy dla procesów projektowych.

## 4. Contains
Skrypty powłoki: architecture.sh, change-impact.sh, contracts.sh, data-model.sh, design-doc.sh, interface.sh, tech-debt.sh.

## 5. Does Not Contain
Nie zawiera samych dokumentów projektowych ani modeli — wyłącznie automatyzację ich tworzenia i weryfikacji.

## 6. Dependencies
Wymaga narzędzi do przetwarzania dokumentów i modeli oraz dostępu do repozytorium dokumentacji.

## 7. Consumers
Architekci, zespoły projektowe, procesy przeglądu architektury i zarządzania długiem technicznym.

## 8. Synchronization
Skrypty synchronizowane z repozytorium przez standardowy mechanizm dystrybucji narzędzi automatyzacji.

## 9. Lifecycle
Ewoluują wraz z procesami projektowymi; wersjonowane w git, aktualizowane przy zmianie standardów architektonicznych.

## 10. Security
Skrypty nie przechowują sekretów; dokumenty projektowe podlegają kontroli dostępu repozytorium.

## 11. Recovery
W razie awarii skrypty można uruchomić ponownie; dokumenty i modele są odtwarzane z repozytorium.

## 12. Drift Detection
Rozbieżności między skryptami a wersją w repozytorium są wykrywane przez mechanizm certyfikacji.
