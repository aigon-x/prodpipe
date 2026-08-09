# ontology

> Katalog definiujący Ontologię — formalny model pojęć, relacji i typów domeny AIGON. Składowa AgentFingerprint.

## 1. Purpose
Definiuje Ontologię — formalny model pojęć, relacji i typów domeny. Stanowi wspólny słownik dla agentów i Runtime.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (Ontologia). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Definicje pojęć, relacji, typów domeny, schematy ontologiczne.

## 5. Does Not Contain
Nie zawiera actual state (instancje, rejestry), nie zawiera sekretów, nie zawiera danych instancyjnych.

## 6. Dependencies
Zależy od `agents/abi` (kontrakt ABI), `agents/genome` (Genome).

## 7. Consumers
Agenci, Runtime, `agents/fingerprint`, `agents/memory` (MemorySchema).

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla Ontologii. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako model domeny, zmienia się przez PR, wycofywany przez deprecację pojęć. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. Model publiczny. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie Ontologii (Git) z faktycznie używanym modelem w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
