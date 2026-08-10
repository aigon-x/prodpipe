# recovery

> Testy odzyskiwania — weryfikują procedury odzyskiwania systemu.

## 1. Purpose
Weryfikuje poprawność procedur odzyskiwania systemu po awariach, w tym przywracanie stanu i ciągłość działania.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji procedur odzyskiwania.

## 4. Contains
Skrypt `recovery.test.sh` oraz scenariusze odzyskiwania.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od procedur odzyskiwania oraz narzędzi do symulacji awarii.

## 7. Consumers
CI/CD, deweloperzy, operatorzy weryfikujący odzyskiwanie.

## 8. Synchronization
Klasa: `CANONICAL` — skrypt testowy jest źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypt testowy i referencje.

## 11. Recovery
`STATUS: UNDEFINED` — procedury odzyskiwania są głównym przedmiotem tych testów.

## 12. Drift Detection
Wykrywanie rozjazdu między definicją procedur odzyskiwania (git) a faktycznym zachowaniem systemu.
