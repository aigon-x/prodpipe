# evidence

> Podkatalog AIGON-X-FS przechowujący dowody (evidence) — artefakty potwierdzające stan / działanie platformy.

## 1. Purpose
Przechowywanie dowodów (evidence) — artefaktów potwierdzających stan / działanie / zgodność platformy.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny AIGON-X-FS nie jest jeszcze przypisany.

## 3. Source of Truth
Runtime (actual state). Dowody są zapisem stanu faktycznego / wykonanych działań.

## 4. Contains
Dowody (evidence) — artefakty potwierdzające stan / działanie / zgodność.

## 5. Does Not Contain
- Kod źródłowy / kontrakty / schematy / polityki (domena Git).
- Sekrety.
- Drugi Source of Truth.

## 6. Dependencies
AIGON-X-FS (katalog nadrzędny), źródła dowodów (Runtime, audyty, testy).

## 7. Consumers
Runtime, audyty, procedury zgodności. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `REPLICATED`. Replikacja dowodów między nodami. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
Dowody powstają w trakcie audytów / działań, wycofywane przez polityki retencji. `STATUS: UNDEFINED` dla pełnego cyklu.

## 10. Security
Klasyfikacja danych runtime'owych. Zakaz sekretów. Ochrona integralności dowodów.

## 11. Recovery
Odzyskiwanie z replik / snapshotów. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — mechanizm wykrywania driftu dla dowodów nie jest zdefiniowany.

## Examples
`STATUS: UNDEFINED`.
