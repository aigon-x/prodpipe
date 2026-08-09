# evals

> Katalog definiujący ewaluacje modeli — definicje i konfiguracje testów ewaluacyjnych modeli ML/AI. Git = desired state.

## 1. Purpose
Definiuje ewaluacje modeli — definicje i konfiguracje testów ewaluacyjnych modeli ML/AI. Git = desired state.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje ewaluacji). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Definicje ewaluacji, konfiguracje testów, manifesty ewaluacji.

## 5. Does Not Contain
Nie zawiera actual state (wyniki ewaluacji), nie zawiera sekretów, nie zawiera danych instancyjnych.

## 6. Dependencies
Zależy od `models/registry` (rejestr), `models/benchmarks` (benchmarki), `models/catalog` (katalog).

## 7. Consumers
Runtime, agenci, `models/catalog`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla definicji ewaluacji. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako definicja ewaluacji, zmienia się przez PR, wycofywany przez deprecację. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie definicji ewaluacji (Git) z faktycznie uruchamianymi ewaluacjami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
