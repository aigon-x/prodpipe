# abi

> Katalog definiujący Agent ABI i Runtime ABI — kontrakty interfejsów, przez które agenci i Runtime komunikują się. Część składowa AgentFingerprint.

## 1. Purpose
Definiuje Agent ABI i Runtime ABI — kontrakty interfejsów komunikacji między agentami a Runtime. Jest składową AgentFingerprint.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kontrakt ABI). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Definicje Agent ABI, Runtime ABI, schematy interfejsów, kontrakty wywołań.

## 5. Does Not Contain
Nie zawiera actual state (aktywne połączenia, rejestry), nie zawiera sekretów, nie zawiera implementacji.

## 6. Dependencies
Zależy od `agents/ontology` (Ontology), `agents/tools` (ToolPack), `agents/prompts` (PromptPack).

## 7. Consumers
Runtime, agenci, `agents/runtime`, `agents/fingerprint`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla kontraktu ABI. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako kontrakt, zmienia się przez PR, wycofywany przez deprecację wersji ABI. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. Kontrakt publiczny. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie kontraktu ABI (Git) z faktycznie używanym ABI w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
