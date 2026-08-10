# mutation

> Testy mutacyjne — mutują kod i weryfikują, że testy wykrywają zmianę.

## 1. Purpose
Weryfikuje jakość testów poprzez celowe mutowanie (zmienianie) kodu i sprawdzanie, czy testy wykrywają wprowadzoną zmianę.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla kodu poddawanego mutacjom.

## 4. Contains
Skrypt `mutation.test.sh` oraz konfiguracja mutacji.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od narzędzi do mutacji kodu oraz frameworka testowego.

## 7. Consumers
CI/CD, deweloperzy, inżynierowie jakości.

## 8. Synchronization
Klasa: `CANONICAL` — skrypt testowy jest źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypt testowy i referencje.

## 11. Recovery
`STATUS: UNDEFINED` — procedury odzyskiwania po testach mutacyjnych.

## 12. Drift Detection
Wykrywanie rozjazdu między pokryciem mutacyjnym (git) a faktyczną skutecznością testów.
