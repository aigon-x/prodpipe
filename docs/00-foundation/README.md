# 00-foundation

> Kanoniczna dokumentacja fundamentów platformy — konstytucja dokumentacyjna, typy dokumentów, lifecycle, metadata, źródła prawdy i granice.

## 1. Purpose
Przechowuje kanoniczne dokumenty definiujące fundamenty dokumentacji AIGON Production Platform: konstytucję dokumentacyjną, typy dokumentów, lifecycle, kontrakt metadata, hierarchię źródeł prawdy oraz granice między dokumentacją a Git/Runtime/FS/Agentami.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER` — owner do przypisania w DOC-RECONCILIATION.

## 3. Source of Truth
Git = desired state (dokumentacja). Dokumenty w tym katalogu definiują kontrakty; faktyczne egzekwowanie to actual state (Runtime/validator).

## 4. Contains
Dokumenty kanoniczne: DOCUMENTATION-CONSTITUTION, DOCUMENT-TYPES, DOCUMENT-LIFECYCLE, DOCUMENT-METADATA, SOURCE-OF-TRUTH, granice (GIT/RUNTIME/FS/AGENT/DOCUMENTATION).

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych, dokumentów domenowych (te żyją w odpowiednich katalogach docs/).

## 6. Dependencies
Zależy od README contract (12 sekcji) i narzędzia `tools/verify documentation`.

## 7. Consumers
Wszystkie katalogi docs/, governance/, dokumenty root, validator dokumentacji.

## 8. Synchronization
Klasa: `CANONICAL` — dokumentacja jest źródłem prawdy w git. Zmiany przechodzą przez Git + verification.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER` — dokumenty foundation są aktywne od momentu utworzenia; ewoluują przez DOC-RECONCILIATION.

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko dokumentacja i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania dokumentacji foundation.

## 12. Drift Detection
Wykrywanie rozjazdu między dokumentacją (git) a faktycznym stanem (Runtime) przez `tools/verify documentation`.

## Status
`STATUS: FOUNDATION PLACEHOLDER`
