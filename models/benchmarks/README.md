# benchmarks

> Katalog definiujący benchmarki modeli — definicje i konfiguracje testów porównawczych modeli ML/AI. Git = desired state.

## 1. Purpose
Definiuje benchmarki modeli — definicje i konfiguracje testów porównawczych modeli ML/AI. Git = desired state.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje benchmarków). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Definicje benchmarków, konfiguracje testów, manifesty benchmarków.

## 5. Does Not Contain
Nie zawiera actual state (wyniki benchmarków), nie zawiera sekretów, nie zawiera danych instancyjnych.

## 6. Dependencies
Zależy od `models/registry` (rejestr), `models/catalog` (katalog), `models/evals` (ewaluacje).

## 7. Consumers
Runtime, agenci, `models/evals`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla definicji benchmarków. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako definicja benchmarku, zmienia się przez PR, wycofywany przez deprecację. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie definicji benchmarków (Git) z faktycznie uruchamianymi benchmarkami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
