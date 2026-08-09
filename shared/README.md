# shared

> Katalog współdzielony AIGON Production Platform — wspólne artefakty, biblioteki, schematy.

## 1. Purpose
Przechowuje współdzielone artefakty: wspólne biblioteki, schematy, definicje używane przez wiele domen.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla artefaktów współdzielonych. Runtime odzwierciedla actual state.

## 4. Contains
Współdzielone biblioteki, schematy, definicje, konwencje używane przez wiele domen.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od contracts, config, governance.

## 7. Consumers
Wszystkie domeny platformy.

## 8. Synchronization
Klasa: `CANONICAL` — artefakty współdzielone są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko definicje i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania artefaktów współdzielonych.

## 12. Drift Detection
Wykrywanie rozjazdu między artefaktami współdzielonymi (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
