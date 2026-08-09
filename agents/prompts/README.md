# prompts

> Katalog definiujący PromptPack — szablony i kontrakty promptów agentów. Składowa AgentFingerprint.

## 1. Purpose
Definiuje PromptPack — szablony i kontrakty promptów używanych przez agentów. Jest składową AgentFingerprint.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (szablony promptów). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Szablony promptów, kontrakty PromptPack, definicje instrukcji systemowych.

## 5. Does Not Contain
Nie zawiera actual state (wygenerowane prompty, konwersacje), nie zawiera sekretów, nie zawiera danych instancyjnych.

## 6. Dependencies
Zależy od `agents/ontology` (Ontology), `agents/skills` (SkillPack), `agents/tools` (ToolPack).

## 7. Consumers
Runtime, agenci, `agents/fingerprint`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla promptów. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako szablon, zmienia się przez PR, wycofywany przez deprecację. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. Prompty mogą zawierać instrukcje wrażliwe — wymagana kontrola dostępu. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie szablonów (Git) z faktycznie używanymi promptami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
