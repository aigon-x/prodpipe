# tools

> Katalog definiujący ToolPack — deklaratywne definicje narzędzi dostępnych agentom. Składowa AgentFingerprint.

## 1. Purpose
Definiuje ToolPack — deklaratywne definicje narzędzi (tools) dostępnych agentom. Jest składową AgentFingerprint.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje narzędzi). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Definicje narzędzi, schematy ToolPack, manifesty narzędzi.

## 5. Does Not Contain
Nie zawiera actual state (aktywne wywołania narzędzi), nie zawiera sekretów, nie zawiera danych instancyjnych.

## 6. Dependencies
Zależy od `agents/ontology` (Ontology), `agents/abi` (kontrakt ABI).

## 7. Consumers
Runtime, agenci, `agents/fingerprint`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla narzędzi. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako definicja narzędzia, zmienia się przez PR, wycofywany przez deprecację. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. Definicje narzędzi mogą ujawniać powierzchnię ataku — wymagana kontrola dostępu. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie definicji narzędzi (Git) z faktycznie dostępnymi narzędziami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
