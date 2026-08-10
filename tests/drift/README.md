# drift

> Testy wykrywania dryfu — weryfikują, że rozjazd konfiguracji i stanu jest wykrywany.

## 1. Purpose
Weryfikuje, że dryf konfiguracji i stanu (rozjazd między desired state a actual state) jest poprawnie wykrywany przez mechanizmy kontrolne.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla konfiguracji, względem której wykrywany jest dryf.

## 4. Contains
Skrypt `drift.test.sh` oraz przypadki testowe wykrywania dryfu.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od mechanizmów wykrywania dryfu oraz narzędzi porównujących stan.

## 7. Consumers
CI/CD, deweloperzy, operatorzy monitorujący spójność konfiguracji.

## 8. Synchronization
Klasa: `CANONICAL` — testy dryfu są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypt testowy i referencje.

## 11. Recovery
`STATUS: UNDEFINED` — procedury odzyskiwania po wykrytym dryfie.

## 12. Drift Detection
Wykrywanie rozjazdu między konfiguracją (git) a faktycznym stanem (Runtime) — to jest główny przedmiot tych testów.
