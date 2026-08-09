# knowledge

> Współdzielona wiedza domenowa, techniczna, operacyjna, incydenty i decyzje.

## 1. Purpose
Przechowuje współdzieloną wiedzę platformy (domain, technical, operational, incidents, decisions) jako artefakty dokumentacyjne.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Wiedza jako artefakty dokumentacyjne.

## 4. Contains
Podkatalogi: `domain/`, `technical/`, `operational/`, `incidents/`, `decisions/`.

## 5. Does Not Contain
Runtime state, sekrety, dane sesyjne, pamięć agentów.

## 6. Dependencies
`shared/canonical` (kontrakty, schematy).

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów — wiedza może zawierać referencje, nie sekrety.

## 11. Recovery
Odzysk z Git.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
