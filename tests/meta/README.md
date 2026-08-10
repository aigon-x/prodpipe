# meta

> Testy meta — testy o samym frameworku testowym.

## 1. Purpose
Weryfikuje poprawność i spójność samego frameworka testowego, jego konfiguracji oraz mechanizmów uruchamiania.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji frameworka testowego.

## 4. Contains
Skrypt `meta.test.sh` oraz testy dotyczące frameworka testowego.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od frameworka testowego, który sam jest przedmiotem testów.

## 7. Consumers
CI/CD, deweloperzy, twórcy frameworka testowego.

## 8. Synchronization
Klasa: `CANONICAL` — skrypt testowy jest źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypt testowy i referencje.

## 11. Recovery
`STATUS: UNDEFINED` — procedury odzyskiwania frameworka testowego.

## 12. Drift Detection
Wykrywanie rozjazdu między definicją frameworka (git) a faktycznym stanem uruchomienia.
