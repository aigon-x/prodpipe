# catalog

> Katalog definiujący katalog modeli — metadane, opisy i atrybuty modeli ML/AI. Git = desired state.

## 1. Purpose
Definiuje katalog modeli — metadane, opisy i atrybuty modeli ML/AI dostępnych w platformie. Git = desired state.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (katalog modeli). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Metadane modeli, opisy, atrybuty, dokumentacja modeli.

## 5. Does Not Contain
Nie zawiera actual state (dostępność), nie zawiera wag modeli, nie zawiera sekretów.

## 6. Dependencies
Zależy od `models/registry` (rejestr), `models/benchmarks` (benchmarki), `models/evals` (ewaluacje).

## 7. Consumers
Runtime, agenci, użytkownicy platformy.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla katalogu. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako wpis katalogu, zmienia się przez PR, wycofywany przez deprecację. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie katalogu (Git) z faktycznie dostępnymi modelami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
