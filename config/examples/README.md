# examples

> Przykłady konfiguracji — dokumentacyjne, NIE aktywne.

## 1. Purpose
Przechowuje przykłady konfiguracji (dokumentacyjne). NIE są aktywne ani commitowane jako działające.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Przykłady dokumentacyjne.

## 4. Contains
Przykładowe pliki konfiguracji.

## 5. Does Not Contain
Aktywne konfiguracje, sekrety, dane maszynowe.

## 6. Dependencies
`config/canonical`, `config/templates`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów — przykłady używają placeholderów.

## 11. Recovery
Odzysk z Git.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
