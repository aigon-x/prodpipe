# policies

> Kanoniczne polityki (policies-as-code) dla platformy AIGON Production.

## 1. Purpose
Przechowuje kanoniczne polityki jako kod (bezpieczeństwo, zgodność, operacje) — stan pożądany.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Kanoniczne polityki.

## 4. Contains
Polityki jako kod (security, compliance, operations) w formie deklaratywnej.

## 5. Does Not Contain
Runtime state, sekrety, dane instancyjne.

## 6. Dependencies
`shared/canonical/schemas` (schematy polityk).

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów — polityki odwołują się do sekretów przez referencje.

## 11. Recovery
Odzysk z Git.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
