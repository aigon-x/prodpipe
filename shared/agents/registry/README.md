# registry

> Rejestr agentów — deklaratywna definicja, NIE runtime state.

## 1. Purpose
Przechowuje deklaratywny rejestr agentów jako stan pożądany. Uwaga: to NIE jest drugi rejestr/SoT — faktyczny stan rejestru agentów żyje w Runtime.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state) dla definicji; faktyczny stan rejestru = Runtime (actual).

## 4. Contains
Deklaratywny rejestr agentów.

## 5. Does Not Contain
Faktyczny stan rejestru (to Runtime), runtime state, sekrety.

## 6. Dependencies
`shared/agents`, `shared/canonical/registry`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git; stan faktyczny odzwierciedlany w Runtime.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Git.

## 12. Drift Detection
Porównanie definicji (Git) vs faktycznego stanu rejestru (Runtime) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
