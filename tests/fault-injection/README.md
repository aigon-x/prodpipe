# fault-injection

> Testy wstrzykiwania awarii — wstrzykują błędy i weryfikują odporność systemu.

## 1. Purpose
Weryfikuje odporność systemu na awarie poprzez celowe wstrzykiwanie błędów (failures) i sprawdzanie, czy system poprawnie je obsługuje.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla scenariuszy wstrzykiwania awarii.

## 4. Contains
Skrypt `fault-injection.test.sh` oraz scenariusze wstrzykiwania awarii.

## 5. Does Not Contain
Nie zawiera sekretów ani danych produkcyjnych.

## 6. Dependencies
Zależy od mechanizmów wstrzykiwania awarii oraz narzędzi do symulacji błędów.

## 7. Consumers
CI/CD, deweloperzy, operatorzy weryfikujący odporność systemu.

## 8. Synchronization
Klasa: `CANONICAL` — skrypt testowy jest źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypt testowy i referencje.

## 11. Recovery
`STATUS: UNDEFINED` — procedury odzyskiwania po wstrzykniętych awariach.

## 12. Drift Detection
Wykrywanie rozjazdu między scenariuszami awarii (git) a faktycznym zachowaniem systemu.
