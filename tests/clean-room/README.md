# clean-room

> Testy clean-room — uruchamiane w izolacji, bez kontaminacji stanem hosta.

## 1. Purpose
Weryfikuje, że testy działają w czystym środowisku, odizolowanym od stanu hosta, bez wpływu zmiennych środowiskowych, cache ani artefaktów z poprzednich uruchomień.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla skryptu testowego i oczekiwanego czystego środowiska.

## 4. Contains
Skrypt `clean-room.test.sh` oraz konfiguracja izolowanego środowiska testowego.

## 5. Does Not Contain
Nie zawiera sekretów, danych produkcyjnych ani stanu runtime.

## 6. Dependencies
Zależy od frameworka testowego oraz narzędzi do izolacji środowiska (sandbox/container).

## 7. Consumers
CI/CD, deweloperzy, operatorzy uruchamiający testy w izolacji.

## 8. Synchronization
Klasa: `CANONICAL` — skrypt testowy jest źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypt testowy i referencje.

## 11. Recovery
`STATUS: UNDEFINED` — procedury odzyskiwania środowiska clean-room.

## 12. Drift Detection
Wykrywanie rozjazdu między definicją czystego środowiska (git) a faktycznym stanem uruchomienia.
