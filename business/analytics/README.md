# analytics

> Katalog definicji analityki biznesowej — schematy i konfiguracje analiz.

## 1. Purpose
Przechowuje definicje analityki biznesowej — schematy, konfiguracje i modele analiz dla warstwy biznesowej.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje analityki). Wyniki analiz to actual state (Runtime).

## 4. Contains
Schematy analiz, definicje metryk, konfiguracje modeli analitycznych, zapytania.

## 5. Does Not Contain
Nie zawiera danych biznesowych, sekretów, stanu runtime.

## 6. Dependencies
`business/contracts`, `business/reporting`.

## 7. Consumers
Warstwa biznesowa, zespół analityczny, zespół platformy.

## 8. Synchronization
`CANONICAL` — definicje analityki są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych analiz, zmienia się przy zmianach metryk, wycofywany gdy analiza znika.

## 10. Security
Definicje analityki mogą dotykać danych wrażliwych. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez walidację: wyniki analiz odbiegają od definicji.

## Examples
`STATUS: UNDEFINED`
