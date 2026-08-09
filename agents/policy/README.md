# policy

> Katalog definiujący PolicyPack — polityki jako kod (policies-as-code) rządzące zachowaniem agentów i Runtime. Składowa AgentFingerprint.

## 1. Purpose
Definiuje PolicyPack — polityki jako kod (policies-as-code) rządzące zachowaniem agentów i Runtime. Jest składową AgentFingerprint.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (polityki). `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Polityki jako kod, reguły autoryzacji, reguły zachowania, schematy PolicyPack.

## 5. Does Not Contain
Nie zawiera actual state (decyzje, logi), nie zawiera sekretów, nie zawiera danych instancyjnych.

## 6. Dependencies
Zależy od `agents/ontology` (Ontology), `agents/abi` (kontrakt ABI).

## 7. Consumers
Runtime (egzekucja polityk), agenci, `agents/fingerprint`.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla polityk. `STATUS: UNDEFINED` dla mechanizmu propagacji do egzekucji.

## 9. Lifecycle
Powstaje jako polityka, zmienia się przez PR, wycofywany przez deprecację reguł. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. Polityki mogą zawierać reguły wrażliwe — wymagana kontrola dostępu do zmian. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie polityk (Git) z faktycznie egzekwowanymi regułami w Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
