# automation

> Katalog automatyzacji — definicje zadań automatycznych i orkiestracji.

## 1. Purpose
Przechowuje definicje automatyzacji — zadania automatyczne, orkiestracje, harmonogramy i procedury zautomatyzowane.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje automatyzacji). Faktyczne wykonanie to actual state (Runtime).

## 4. Contains
Definicje zadań automatycznych, orkiestracje, harmonogramy (cron), procedury zautomatyzowane.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`tools/scripts`, `tools/utilities`, `tools/ci`.

## 7. Consumers
Runtime (wykonanie), zespół operacyjny, zespół platformy.

## 8. Synchronization
`CANONICAL` — definicje automatyzacji są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych zadań, zmienia się przy zmianach procesów, wycofywany gdy zadanie znika.

## 10. Security
Automatyzacje mogą dotykać wrażliwych operacji. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez walidację: wykonanie automatyzacji odbiega od definicji.

## Examples
`STATUS: UNDEFINED`
