# registry

> Katalog definiujący rejestr modeli — deklaratywny katalog modeli ML/AI dostępnych w platformie. Git = desired state; actual state rejestru żyje w Runtime.

## 1. Purpose
Definiuje rejestr modeli — deklaratywny katalog modeli ML/AI dostępnych w platformie. Git = desired state; actual state rejestru (dostępność, wersje) żyje w Runtime.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (rejestr modeli). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Definicje rejestru modeli, manifesty modeli, deklaracje wersji.

## 5. Does Not Contain
Nie zawiera actual state (dostępność, topologia), nie zawiera wag modeli, nie zawiera sekretów.

## 6. Dependencies
Zależy od `models/catalog` (katalog), `models/weights` (wagi), `agents/abi` (kontrakt ABI).

## 7. Consumers
Runtime, agenci, `models/catalog`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla rejestru. `STATUS: UNDEFINED` dla mechanizmu propagacji do actual state.

## 9. Lifecycle
Powstaje jako wpis rejestru, zmienia się przez PR, wycofywany przez deprecację modelu. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie rejestru (Git) z faktycznie dostępnymi modelami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
