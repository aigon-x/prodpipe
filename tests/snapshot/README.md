# snapshot

> Testy snapshot — porównują stan z zapisanymi snapshotami.

## 1. Purpose
Weryfikuje, że stan systemu jest zgodny z zapisanymi snapshotami, wykrywając nieoczekiwane zmiany w danych lub konfiguracji.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla zapisanych snapshotów.

## 4. Contains
Skrypt `snapshot.test.sh` oraz zapisane pliki snapshot.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od narzędzi do tworzenia i porównywania snapshotów.

## 7. Consumers
CI/CD, deweloperzy, operatorzy weryfikujący spójność stanu.

## 8. Synchronization
Klasa: `CANONICAL` — pliki snapshot są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypt testowy i referencje.

## 11. Recovery
`STATUS: UNDEFINED` — procedury odzyskiwania/aktualizacji snapshotów.

## 12. Drift Detection
Wykrywanie rozjazdu między stanem systemu a zapisanymi snapshotami (git).
