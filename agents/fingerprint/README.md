# fingerprint

> Katalog definiujący AgentFingerprint — kompozycyjną definicję agenta złożoną z ABI, Ontologii, Genome, PolicyPack, SkillPack, MemorySchema, PromptPack, ToolPack i ConfigSchema. Agenci są definiowani przez fingerprint, nie przez hardcoded config.

## 1. Purpose
Definiuje AgentFingerprint — kompozycyjną definicję agenta. Agenci są definiowani przez swój fingerprint (Runtime ABI, Agent ABI, Ontology, Genome, PolicyPack, SkillPack, MemorySchema, PromptPack, ToolPack, ConfigSchema), nie przez hardcoded config.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje fingerprintów). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Definicje AgentFingerprint, kompozycje składowych, manifesty tożsamości agentów.

## 5. Does Not Contain
Nie zawiera actual state (aktywne instancje agentów), nie zawiera sekretów, nie zawiera danych instancyjnych.

## 6. Dependencies
Zależy od wszystkich katalogów składowych: `agents/abi`, `agents/ontology`, `agents/genome`, `agents/policy`, `agents/skills`, `agents/memory`, `agents/prompts`, `agents/tools`, `agents/config`.

## 7. Consumers
Runtime (rejestracja agentów), agenci, narzędzia weryfikacji tożsamości.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla fingerprintów. `STATUS: UNDEFINED` dla mechanizmu propagacji do Runtime.

## 9. Lifecycle
Powstaje jako kompozycja składowych, zmienia się przez PR, wycofywany przez deprecację fingerprintu. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. Fingerprint definiuje tożsamość — wymagana kontrola dostępu do zmian. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie fingerprintów (Git) z faktycznie zarejestrowanymi agentami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
