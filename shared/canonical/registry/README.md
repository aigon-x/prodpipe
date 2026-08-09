# registry

> Kanoniczny rejestr (registry) — deklaratywna definicja rejestrów, NIE runtime state.

## 1. Purpose
Przechowuje kanoniczne definicje rejestrów (registry) jako stan pożądany. Uwaga: to NIE jest drugi rejestr/SoT — to deklaratywna definicja, a faktyczny stan rejestrów żyje w Runtime.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Definicje rejestrów; faktyczny stan rejestrów = Runtime (actual).

## 4. Contains
Deklaratywne definicje rejestrów (registry definitions).

## 5. Does Not Contain
Faktyczny stan rejestrów (to Runtime), runtime state, sekrety.

## 6. Dependencies
`shared/canonical/contracts`, `shared/canonical/schemas`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git; stan faktyczny odzwierciedlany w Runtime.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów — tylko definicje rejestrów.

## 11. Recovery
Odzysk z Git.

## 12. Drift Detection
Porównanie definicji (Git) vs faktycznego stanu rejestrów (Runtime) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
