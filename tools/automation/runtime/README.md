# runtime

> Automatyzacja zarządzania runtime — certyfikacja ciągła, źródło prawdy, zarządzanie ryzykiem zmian.

## 1. Purpose
Automatyzuje zarządzanie runtime: ciągłą certyfikację, weryfikację selektywną, samocertyfikację, zarządzanie ryzykiem zmian, spójność wiedzy i dokumentacji oraz zapewnienie źródła prawdy.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Runtime i jego rejestr stanu są źródłem prawdy dla procesów certyfikacji i zarządzania zmianami.

## 4. Contains
Skrypty powłoki: change-risk.sh, continuous-certification.sh, documentation.sh, gap-discovery.sh, generated-artifact.sh, knowledge-consistency.sh, pipeline-governance.sh, selective-verification.sh, self-certification.sh, source-of-truth.sh, temporal-assurance.sh, unknown-management.sh.

## 5. Does Not Contain
Nie zawiera samego runtime ani jego stanu — wyłącznie automatyzację procesów zarządzania i certyfikacji.

## 6. Dependencies
Wymaga dostępu do runtime i jego API oraz do rejestrów stanu i wiedzy.

## 7. Consumers
Procesy certyfikacji, zespoły operacyjne i mechanizmy zapewnienia zgodności platformy.

## 8. Synchronization
Skrypty synchronizowane z repozytorium przez standardowy mechanizm dystrybucji narzędzi automatyzacji.

## 9. Lifecycle
Ewoluują wraz z procesami zarządzania runtime; wersjonowane w git, aktualizowane przy zmianie polityk certyfikacji.

## 10. Security
Skrypty nie przechowują sekretów; dostęp do runtime podlega kontroli dostępu i audytowi.

## 11. Recovery
W razie awarii skrypty można uruchomić ponownie; stan certyfikacji jest odtwarzany z rejestrów runtime.

## 12. Drift Detection
Rozbieżności między skryptami a wersją w repozytorium oraz między stanem runtime a oczekiwanym są wykrywane przez mechanizm certyfikacji.
