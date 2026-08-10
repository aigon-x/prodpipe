# property

> Testy property-based — weryfikują, że niezmienniki (invariants) są zachowane.

## 1. Purpose
Weryfikuje, że niezmienniki systemu są zachowane dla szerokiego zakresu losowo generowanych danych wejściowych.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji niezmienników.

## 4. Contains
Skrypt `property.test.sh` oraz definicje właściwości/niezmienników.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od narzędzi do generowania danych oraz frameworka testowego.

## 7. Consumers
CI/CD, deweloperzy, inżynierowie jakości.

## 8. Synchronization
Klasa: `CANONICAL` — skrypt testowy jest źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypt testowy i referencje.

## 11. Recovery
`STATUS: UNDEFINED` — procedury odzyskiwania po testach property-based.

## 12. Drift Detection
Wykrywanie rozjazdu między definicją niezmienników (git) a faktycznym zachowaniem systemu.
