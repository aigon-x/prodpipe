## Opis zmiany

<!-- Krótko: co i dlaczego. -->

## Typ zmiany

- [ ] feature
- [ ] fix
- [ ] migration
- [ ] security
- [ ] release

## Granice architektury (CI)

- [ ] Nie modyfikuje agent → canonical state / governance
- [ ] Nie modyfikuje business → runtime internals / aigon-x-fs internals
- [ ] Brak hardcoded IP / hostname / node count / kernel count
- [ ] Brak sekretów w repo
- [ ] Brak `:latest` image w produkcji
- [ ] Brak drugiego SoT / registry / memory

## Source of Truth

- [ ] Każda zmiana ma jednego właściciela (OWNERSHIP.md)
- [ ] Git = desired state, Runtime = actual state (bez mieszania)

## Synchronizacja

- [ ] Klasa synchronizacji oznaczona (CANONICAL / REPLICATED / GENERATED / CACHE / SESSION / EPHEMERAL)

## DoD

- [ ] Build przechodzi
- [ ] Unit tests przechodzą
- [ ] Integration tests przechodzą
- [ ] Regression tests przechodzą
- [ ] SOT checks przechodzą
- [ ] Drift checks przechodzą
- [ ] Feature tests przechodzą
- [ ] Trzech świadków (Three Witnesses) potwierdza
- [ ] HELIOS gate przechodzi
- [ ] BASELINE zaktualizowany
