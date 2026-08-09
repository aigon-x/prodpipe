# skills

> Katalog definiujący SkillPack — deklaratywne definicje umiejętności agentów. Składowa AgentFingerprint.

## 1. Purpose
Definiuje SkillPack — deklaratywne definicje umiejętności (skills) dostępnych agentom. Jest składową AgentFingerprint.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje skilli). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Definicje skilli, schematy SkillPack, manifesty umiejętności.

## 5. Does Not Contain
Nie zawiera actual state (aktywne wywołania skilli), nie zawiera sekretów, nie zawiera danych instancyjnych.

## 6. Dependencies
Zależy od `agents/ontology` (Ontology), `agents/tools` (ToolPack), `agents/prompts` (PromptPack).

## 7. Consumers
Runtime, agenci, `agents/fingerprint`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla skilli. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako definicja skilla, zmienia się przez PR, wycofywany przez deprecację. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie definicji skilli (Git) z faktycznie dostępnymi skillami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
