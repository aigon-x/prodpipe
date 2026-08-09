# memory

> Katalog definiujący MemorySchema — schematy pamięci agentów. Składowa AgentFingerprint. Definiuje strukturę, nie przechowuje danych pamięci.

## 1. Purpose
Definiuje MemorySchema — schematy struktury pamięci agentów. Jest składową AgentFingerprint. Definiuje strukturę, nie przechowuje danych pamięci.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (schematy pamięci). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Schematy MemorySchema, definicje struktur pamięci, kontrakty trwałości.

## 5. Does Not Contain
Nie zawiera actual state (dane pamięci agentów), nie zawiera sekretów, nie zawiera instancyjnych danych pamięci.

## 6. Dependencies
Zależy od `agents/ontology` (Ontology), `agents/abi` (kontrakt ABI).

## 7. Consumers
Runtime (trwałość pamięci), agenci, `agents/fingerprint`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla schematów. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako schemat, zmienia się przez PR, wycofywany przez deprecację schematu. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. Schematy mogą definiować pola wrażliwe — wymagana kontrola dostępu. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury odzysku danych pamięci.

## 12. Drift Detection
Porównanie schematów (Git) z faktycznie używanymi schematami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
