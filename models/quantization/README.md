# quantization

> Katalog definiujący kwantyzację modeli — konfiguracje i definicje kwantyzacji modeli ML/AI. Git = desired state.

## 1. Purpose
Definiuje kwantyzację modeli — konfiguracje i definicje kwantyzacji modeli ML/AI. Git = desired state.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje kwantyzacji). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Definicje kwantyzacji, konfiguracje, manifesty kwantyzowanych modeli.

## 5. Does Not Contain
Nie zawiera actual state (aktywne kwantyzacje), nie zawiera wag kwantyzowanych (artefakty poza Git), nie zawiera sekretów.

## 6. Dependencies
Zależy od `models/registry` (rejestr), `models/weights` (wagi), `models/adapters` (adaptery).

## 7. Consumers
Runtime, agenci, `models/registry`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla definicji kwantyzacji. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako definicja kwantyzacji, zmienia się przez PR, wycofywany przez deprecację. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie definicji kwantyzacji (Git) z faktycznie używanymi kwantyzacjami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
