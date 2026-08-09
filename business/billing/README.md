# billing

> Katalog konfiguracji rozliczeń — schematy i definicje modeli rozliczeniowych.

## 1. Purpose
Przechowuje konfiguracje rozliczeń (billing) — schematy, definicje modeli rozliczeniowych, taryf i metryk rozliczeniowych platformy.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (schematy/definicje). Faktyczne rozliczenia to actual state (Runtime).

## 4. Contains
Schematy modeli rozliczeniowych, definicje taryf, metryki rozliczeniowe, szablony faktur.

## 5. Does Not Contain
Nie zawiera danych finansowych rzeczywistych klientów, sekretów, stanu runtime.

## 6. Dependencies
`business/contracts`, `business/tenants`.

## 7. Consumers
Warstwa biznesowa, zespół finansowy, Runtime (egzekwowanie metryk).

## 8. Synchronization
`CANONICAL` — schematy są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych modeli rozliczeniowych, zmienia się przy zmianach taryf, wycofywany gdy model znika.

## 10. Security
Wysoka wrażliwość — definicje rozliczeń. Dostęp ograniczony do zespołu finansowego i platformy.

## 11. Recovery
Odzyskiwane z git (checkout). Dane rozliczeniowe w runtime odtwarzane z definicji.

## 12. Drift Detection
Drift wykrywany przez walidację: metryki rozliczeniowe odbiegają od definicji.

## Examples
`STATUS: UNDEFINED`
