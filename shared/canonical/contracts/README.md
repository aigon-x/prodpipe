# contracts

> Kanoniczne kontrakty (umowy) między komponentami AIGON Production Platform.

## 1. Purpose
Przechowuje kanoniczne definicje kontraktów (ABI, API, zdarzenia, tożsamość) jako stan pożądany.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Kanoniczna definicja kontraktów.

## 4. Contains
Definicje kontraktów: runtime-abi, agent-abi, capability, mesh, filesystem, evidence, api, events, security, identity.

## 5. Does Not Contain
Implementacje, runtime state, sekrety, wygenerowane artefakty.

## 6. Dependencies
`shared/canonical/schemas` (schematy kontraktów).

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów — tylko definicje kontraktów.

## 11. Recovery
Odzysk z Git.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
