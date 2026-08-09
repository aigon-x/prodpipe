# adapters

> Katalog definiujący adaptery modeli — konfiguracje i definicje adapterów (LoRA, fine-tuning) dla modeli ML/AI. Git = desired state.

## 1. Purpose
Definiuje adaptery modeli — konfiguracje i definicje adapterów (LoRA, fine-tuning) dla modeli ML/AI. Git = desired state.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje adapterów). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Definicje adapterów, konfiguracje fine-tuningu, manifesty adapterów.

## 5. Does Not Contain
Nie zawiera actual state (aktywne adaptery), nie zawiera wag adapterów (artefakty poza Git), nie zawiera sekretów.

## 6. Dependencies
Zależy od `models/registry` (rejestr), `models/weights` (wagi), `models/quantization` (kwantyzacja).

## 7. Consumers
Runtime, agenci, `models/registry`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla definicji adapterów. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako definicja adaptera, zmienia się przez PR, wycofywany przez deprecację. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie definicji adapterów (Git) z faktycznie używanymi adapterami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
