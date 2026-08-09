# config

> Katalog definiujący ConfigSchema — schematy konfiguracji agentów i Runtime. Składowa AgentFingerprint. Definiuje strukturę, nie przechowuje wartości konfiguracji.

## 1. Purpose
Definiuje ConfigSchema — schematy konfiguracji agentów i Runtime. Jest składową AgentFingerprint. Definiuje strukturę, nie przechowuje wartości konfiguracji.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (schematy konfiguracji). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Schematy ConfigSchema, definicje struktury konfiguracji, walidatory.

## 5. Does Not Contain
Nie zawiera actual state (wartości konfiguracji), nie zawiera sekretów, nie zawiera instancyjnych wartości.

## 6. Dependencies
Zależy od `agents/abi` (kontrakt ABI), `agents/ontology` (Ontology).

## 7. Consumers
Runtime, agenci, `agents/fingerprint`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla schematów. `STATUS: UNDEFINED` dla mechanizmu propagacji.

## 9. Lifecycle
Powstaje jako schemat, zmienia się przez PR, wycofywany przez deprecację. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. Schematy mogą definiować pola wrażliwe — wymagana kontrola dostępu. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie schematów (Git) z faktycznie używanymi schematami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
