# backups

> Katalog kopii zapasowych — przechowywanie kopii zapasowych artefaktów.

## 1. Purpose
Przechowuje kopie zapasowe (backups) — kopie zapasowe artefaktów, konfiguracji i danych do odzyskiwania.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje backupów). Faktyczne kopie to actual state (Runtime).

## 4. Contains
Kopie zapasowe, archiwa, snapshoty, eksporty danych.

## 5. Does Not Contain
Nie zawiera sekretów (kopie sekretów żyją w secrets manager), stanu runtime.

## 6. Dependencies
`tools/automation`, `tools/scripts`.

## 7. Consumers
Zespół operacyjny, zespół platformy, procedury odzyskiwania.

## 8. Synchronization
`REPLICATED` — kopie są replikowane z desired state przez automatyzację; definicje są `CANONICAL` w git.

## 9. Lifecycle
Powstaje przy każdym backupie, zmienia się przy nowych cyklach, wycofywany gdy nieaktualny.

## 10. Security
Kopie mogą zawierać dane wrażliwe. Dostęp ograniczony do zespołu operacyjnego.

## 11. Recovery
Kopie służą do odzyskiwania; definicje backupów odzyskiwane z git.

## 12. Drift Detection
Drift wykrywany przez walidację: kopie odbiegają od definicji backupów.

## Examples
`STATUS: UNDEFINED`
