# RECOVERY — AIGON Production Platform

> **STATUS: UNDEFINED** — procedury odzyskiwania w fazie genesis. Ramy zdefiniowane; szczegóły w toku.

## Zasada

- **Git = desired state** — git jest odtwarzalny (reproducible). Z gita można odtworzyć stan pożądany.
- **Runtime = actual state** — runtime data żyje w AIGON-X-FS, nie w gicie.
- **Backup / restore** — w `deployment/backup/` i `deployment/restore/`, `operations/backup/` i `operations/restore/`.

## Poziomy odzyskiwania

1. **Kod / konfiguracja / kontrakty** — z gita (desired state).
2. **Runtime data** — z AIGON-X-FS (backup / snapshots / shards).
3. **Sekrety** — z systemu zarządzania sekretami (NIGDY z gita).
4. **Artefakty / evidence** — z `artifacts/` (manifests, digests, evidence).

## Zasady

- **Nic nie kasuj** — zamiast usuwania, kwarantanna (`archive/quarantine/`).
- **Resurrection test** — przed usunięciem legacy, test odtworzenia.
- **Nigdy nie usuwaj przez grep/regex** — pełny proces DISCOVER→AST→CALL GRAPH→RUNTIME REACHABILITY→DEPLOYMENT REACHABILITY→DECISION→QUARANTINE→ARCHIVE→RESURRECTION TEST→DELETE.

## Status

**STATUS: UNDEFINED** — ramy zdefiniowane; procedury w toku.
