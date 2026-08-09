# cemetery

> Granica repozytorium AIGON Production Platform — artefakty wycofane / martwe.

## 1. Purpose
Miejsce dla artefaktów wycofanych / martwych (nie do odzyskania). Granica repozytorium, nie magazyn danych.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla artefaktów w cmentarzu. Runtime odzwierciedla actual state.

## 4. Contains
Artefakty oznaczone jako DELETE po procesie archiwizacji. Elementy, które przeszły pełny cykl: DISCOVER → ... → DECISION → QUARANTINE → ARCHIVE → RESURRECTION TEST → DELETE.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state. Nie kopiuje legacy bez kontrolowanej ścieżki migracji.

## 6. Dependencies
Zależy od archive, governance, docs.

## 7. Consumers
Operatorzy, architekci, audytorzy.

## 8. Synchronization
Klasa: `CANONICAL` — artefakty w cmentarzu są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER` — nie zaimplementowano.

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko artefakty i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania artefaktów z cmentarza.

## 12. Drift Detection
Wykrywanie rozjazdu między artefaktami w cmentarzu (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
