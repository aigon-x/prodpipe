# negative

> Testy negatywne — weryfikują, że system odrzuca nieprawidłowe dane wejściowe.

## 1. Purpose
Weryfikuje, że system poprawnie odrzuca nieprawidłowe dane wejściowe, nieprawidłowe żądania i nieoczekiwane warunki.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji nieprawidłowych danych wejściowych.

## 4. Contains
Skrypt `negative.test.sh` oraz przypadki testowe z nieprawidłowymi danymi.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od frameworka testowego oraz systemu poddawanego testom.

## 7. Consumers
CI/CD, deweloperzy, operatorzy weryfikujący walidację wejścia.

## 8. Synchronization
Klasa: `CANONICAL` — skrypt testowy jest źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypt testowy i referencje.

## 11. Recovery
`STATUS: UNDEFINED` — procedury odzyskiwania po testach negatywnych.

## 12. Drift Detection
Wykrywanie rozjazdu między definicją walidacji (git) a faktycznym zachowaniem systemu.
