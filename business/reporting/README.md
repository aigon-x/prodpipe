# reporting

> Katalog definicji raportów biznesowych — schematy i szablony raportów.

## 1. Purpose
Przechowuje definicje raportów biznesowych — schematy, szablony i konfiguracje raportów dla warstwy biznesowej.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje raportów). Wygenerowane raporty to actual state (GENERATED).

## 4. Contains
Schematy raportów, szablony, definicje metryk raportowanych, konfiguracje generowania.

## 5. Does Not Contain
Nie zawiera wygenerowanych raportów (te żyją w `artifacts/reports`), danych biznesowych, sekretów.

## 6. Dependencies
`business/contracts`, `business/analytics`.

## 7. Consumers
Warstwa biznesowa, zespół analityczny, zespół platformy.

## 8. Synchronization
`CANONICAL` — definicje raportów są źródłem prawdy w git; wygenerowane raporty to `GENERATED`.

## 9. Lifecycle
Powstaje przy definiowaniu nowych raportów, zmienia się przy zmianach metryk, wycofywany gdy raport znika.

## 10. Security
Definicje raportów mogą dotykać danych wrażliwych. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout). Raporty regenerowane z definicji.

## 12. Drift Detection
Drift wykrywany przez walidację: wygenerowane raporty odbiegają od definicji.

## Examples
`STATUS: UNDEFINED`
