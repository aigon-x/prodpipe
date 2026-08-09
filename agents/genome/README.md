# genome

> Katalog definiujący Genome — deklaratywną specyfikację tożsamości i zdolności agenta. Składowa AgentFingerprint.

## 1. Purpose
Definiuje Genome — deklaratywną specyfikację tożsamości, zdolności i zachowania agenta. Jest składową AgentFingerprint.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (Genome). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Specyfikacje Genome agentów, deklaracje zdolności, tożsamości, zachowań.

## 5. Does Not Contain
Nie zawiera actual state (aktywne instancje agentów), nie zawiera sekretów, nie zawiera danych instancyjnych.

## 6. Dependencies
Zależy od `agents/ontology` (Ontology), `agents/policy` (PolicyPack), `agents/skills` (SkillPack).

## 7. Consumers
Runtime, agenci, `agents/fingerprint`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla Genome. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako specyfikacja agenta, zmienia się przez PR, wycofywany przez deprecację Genome. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie Genome (Git) z faktycznie zarejestrowaną tożsamością agenta w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
