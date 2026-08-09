# local

> Konfiguracja lokalna (LOCAL) — maszynowa, NIGDY nie commitowana.

## 1. Purpose
Przechowuje konfiguracje lokalne (LOCAL) — specyficzne dla maszyny. NIGDY nie są commitowane do Git.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — konfiguracja lokalna jest maszynowa; prawda w `config/canonical` (Git).

## 4. Contains
Konfiguracje lokalne (LOCAL) — specyficzne dla maszyny.

## 5. Does Not Contain
Konfiguracje kanoniczne/generowane, sekrety (lub tylko referencje), dane commitowane.

## 6. Dependencies
`config/canonical`, `config/generated`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`LOCAL` — specyficzne dla maszyny; nie synchronizowane do Git.

## 9. Lifecycle
Powstaje lokalnie, zmienia się lokalnie, wycofywany przez usunięcie lokalne.

## 10. Security
Brak sekretów w Git; lokalne sekrety poza repozytorium.

## 11. Recovery
Regeneracja z `config/canonical` i `config/generated`.

## 12. Drift Detection
Porównanie z `config/canonical` (źródło) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
