# runtime

> Katalog definiujący kontrakt Runtime AIGON Production Platform — ABI, zachowanie i granice warstwy wykonawczej. Zawiera deklaratywne specyfikacje, nie sam kod wykonawczy.

## 1. Purpose
Definiuje kontrakt i deklaratywne specyfikacje warstwy Runtime (ABI, zachowanie, granice). Tu żyje "desired state" kontraktu Runtime; sam Runtime (actual state) działa poza tym katalogiem.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kontrakt Runtime). Actual state Runtime (topologia, zdrowie, rejestr) żyje w Runtime i jest odpytywany, nie przechowywany tu. `STATUS: UNDEFINED` dla wskazania konkretnego pliku SoT.

## 4. Contains
Specyfikacje ABI Runtime, deklaratywne kontrakty zachowania, granice odpowiedzialności, schematy konfiguracji Runtime.

## 5. Does Not Contain
Nie zawiera actual state Runtime (zdrowie, topologia, rejestry), nie zawiera sekretów, nie zawiera kodu wykonawczego Runtime.

## 6. Dependencies
Zależy od `agents/abi` (kontrakt ABI), `agents/fingerprint` (AgentFingerprint), `agents/config` (ConfigSchema).

## 7. Consumers
Runtime (actual state), agenci definiowani przez AgentFingerprint, narzędzia weryfikacji zgodności kontraktu.

## 8. Synchronization
`CANONICAL` — Git jest źródłem prawdy dla kontraktu. `STATUS: UNDEFINED` dla mechanizmu propagacji do actual state.

## 9. Lifecycle
Powstaje jako specyfikacja kontraktu, zmienia się przez PR do Git, wycofywany przez deprecację kontraktu. `STATUS: UNDEFINED` dla szczegółów.

## 10. Security
Brak sekretów. Kontrakt publiczny platformy. `STATUS: UNDEFINED` dla klasyfikacji danych.

## 11. Recovery
Odzysk z Git (desired state). `STATUS: UNDEFINED` dla procedury odzysku actual state.

## 12. Drift Detection
Porównanie kontraktu (Git) z actual state Runtime. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu.

## Examples
`STATUS: UNDEFINED`
