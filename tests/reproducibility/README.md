# reproducibility

> Testy odtwarzalności — weryfikują, że buildy są odtwarzalne.

## 1. Purpose
Weryfikuje, że buildy są odtwarzalne — identyczne dane wejściowe dają identyczne wyniki niezależnie od środowiska i czasu.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji odtwarzalnego builda.

## 4. Contains
Skrypt `reproducibility.test.sh` oraz konfiguracja odtwarzalnego builda.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od narzędzi build oraz mechanizmów porównywania artefaktów.

## 7. Consumers
CI/CD, deweloperzy, operatorzy weryfikujący odtwarzalność.

## 8. Synchronization
Klasa: `CANONICAL` — skrypt testowy jest źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko skrypt testowy i referencje.

## 11. Recovery
`STATUS: UNDEFINED` — procedury odzyskiwania po nieodtwarzalnym buildzie.

## 12. Drift Detection
Wykrywanie rozjazdu między definicją odtwarzalności (git) a faktycznym wynikiem builda.
