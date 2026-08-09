# weights

> Katalog definiujący zarządzanie wagami modeli — referencje, manifesty i polityki przechowywania wag ML/AI. Wagi jako artefakty binarne nie są przechowywane w Git.

## 1. Purpose
Definiuje zarządzanie wagami modeli — referencje, manifesty i polityki przechowywania wag ML/AI. Wagi jako artefakty binarne nie są przechowywane w Git.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (manifesty/referencje wag). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Manifesty wag, referencje do artefaktów, polityki przechowywania.

## 5. Does Not Contain
Nie zawiera binarnych wag modeli (artefakty poza Git), nie zawiera actual state, nie zawiera sekretów.

## 6. Dependencies
Zależy od `models/registry` (rejestr), `models/quantization` (kwantyzacja), zewnętrznego storage artefaktów.

## 7. Consumers
Runtime, agenci, `models/registry`.

## 8. Synchronization
`REPLICATED` — manifesty w Git, artefakty replikowane z zewnętrznego storage. `STATUS: UNDEFINED` dla mechanizmu replikacji.

## 9. Lifecycle
Powstaje jako manifest, zmienia się przez PR, wycofywany przez deprecację wersji wag. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. Wagi mogą być wrażliwe IP — wymagana kontrola dostępu do artefaktów. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk manifestów z Git; odzysk artefaktów z zewnętrznego storage. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie manifestów (Git) z faktycznie dostępnymi wagami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
