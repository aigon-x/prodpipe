# reports

> Katalog raportów — wygenerowane raporty operacyjne i biznesowe.

## 1. Purpose
Przechowuje wygenerowane raporty — raporty operacyjne, biznesowe i techniczne generowane przez platformę.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje raportów). Wygenerowane raporty to actual state (`GENERATED`).

## 4. Contains
Wygenerowane raporty, eksporty, agregacje wyników.

## 5. Does Not Contain
Nie zawiera definicji raportów (te żyją w `business/reporting`), stanu runtime, sekretów.

## 6. Dependencies
`business/reporting`, `tools/automation`.

## 7. Consumers
Zespół operacyjny, warstwa biznesowa, zespół platformy.

## 8. Synchronization
`GENERATED` — raporty są generowane z definicji przez automatyzację; definicje są `CANONICAL` w git.

## 9. Lifecycle
Powstaje przy każdym generowaniu, zmienia się przy nowych przebiegach, archiwizowany gdy nieaktualny.

## 10. Security
Raporty mogą zawierać dane wrażliwe. Dostęp ograniczony do zespołu.

## 11. Recovery
Regenerowane z definicji; definicje odzyskiwane z git.

## 12. Drift Detection
Drift wykrywany przez walidację: wygenerowane raporty odbiegają od definicji.

## Examples
`STATUS: UNDEFINED`
