# ai

> Automatyzacja pełnego cyklu życia modeli AI/ML — od przygotowania danych po wycofanie.

## 1. Purpose
Zapewnia skrypty automatyzujące cały cykl życia modeli AI/ML: przygotowanie danych, trenowanie, ocenę, wdrożenie, obserwację i wycofanie. Umożliwia powtarzalne i audytowalne operacje na modelach.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Definicje modeli, konfiguracje treningu i metadane wersji znajdują się w centralnych plikach konfiguracyjnych repozytorium oraz w rejestrze artefaktów modeli.

## 4. Contains
Skrypty powłoki: data-prep.sh, deploy.sh, eval.sh, observe.sh, package.sh, retire.sh, retrain.sh, train.sh, validate.sh.

## 5. Does Not Contain
Nie zawiera samych modeli ani danych treningowych — wyłącznie automatyzację procesów wokół nich. Nie zawiera logiki wnioskowania ani serwowania modeli.

## 6. Dependencies
Wymaga środowiska wykonawczego AI/ML (frameworki treningowe, narzędzia oceny) oraz dostępu do magazynu danych i artefaktów. Zależy od wspólnych bibliotek automatyzacji.

## 7. Consumers
Pipeline'y CI/CD, inżynierowie ML, zespoły operacyjne oraz procesy certyfikacji modeli.

## 8. Synchronization
Skrypty są synchronizowane z repozytorium przez standardowy mechanizm dystrybucji narzędzi automatyzacji; zmiany wchodzą w życie po aktualizacji gałęzi.

## 9. Lifecycle
Skrypty ewoluują wraz z procesem ML; wersjonowane w git, wycofywane gdy proces ulega zmianie lub zastąpieniu.

## 10. Security
Skrypty nie przechowują sekretów; dostęp do danych i artefaktów modeli podlega kontroli dostępu środowiska wykonawczego.

## 11. Recovery
W przypadku awarii skrypt można ponownie uruchomić z repozytorium; stany pośrednie są odtwarzane z artefaktów i logów procesu.

## 12. Drift Detection
Zmiany w skryptach są wykrywane przez porównanie z wersją w repozytorium; rozbieżności raportowane przez mechanizm certyfikacji.
