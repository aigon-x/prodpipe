# golden

> Testy golden/master — porównują wyjście z referencyjnym wzorcem.

## 1. Purpose
Weryfikuje, że wyjście systemu jest zgodne z referencyjnym wzorcem (golden reference), wykrywając nieoczekiwane zmiany w zachowaniu.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla plików golden reference.

## 4. Contains
Skrypt `golden.test.sh` oraz pliki referencyjne (golden files).

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od narzędzi do porównywania wyjścia z referencją.

## 7. Consumers
CI/CD, deweloperzy, operatorzy weryfikujący stabilność wyjścia.

## 8. Synchronization
Klasa: `CANONICAL` — pliki golden są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypt testowy i referencje.

## 11. Recovery
`STATUS: UNDEFINED` — procedury odzyskiwania/aktualizacji plików golden.

## 12. Drift Detection
Wykrywanie rozjazdu między wyjściem systemu a referencyjnym wzorcem (git).
