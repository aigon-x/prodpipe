# events

> Podkatalog AIGON-X-FS przechowujący zdarzenia (events) — zapis zdarzeń runtime'owych platformy.

## 1. Purpose
Przechowywanie zdarzeń (events) — zapisu zdarzeń runtime'owych platformy AIGON Production Platform.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny AIGON-X-FS nie jest jeszcze przypisany.

## 3. Source of Truth
Runtime (actual state). Zdarzenia są zapisem stanu faktycznego w czasie.

## 4. Contains
Zdarzenia (events) runtime'owe platformy.

## 5. Does Not Contain
- Kod źródłowy / kontrakty / schematy / polityki (domena Git).
- Sekrety.
- Drugi Source of Truth.

## 6. Dependencies
AIGON-X-FS (katalog nadrzędny), źródła zdarzeń (Runtime, komponenty mesh).

## 7. Consumers
Runtime, komponenty mesh, obserwowalność. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `REPLICATED` / `EPHEMERAL`. Zdarzenia mogą być efemeryczne lub replikowane. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
Zdarzenia powstają w trakcie działania, wycofywane przez polityki retencji. `STATUS: UNDEFINED` dla pełnego cyklu.

## 10. Security
Klasyfikacja danych runtime'owych. Zakaz sekretów. Granice wg tenantów/użytkowników.

## 11. Recovery
Odzyskiwanie z replik / snapshotów. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — mechanizm wykrywania driftu dla zdarzeń nie jest zdefiniowany.

## Examples
`STATUS: UNDEFINED`.
