# secrets

> Katalog sekretów AIGON Production Platform — referencje, rotacja, schematy, szablony.

## 1. Purpose
Przechowuje artefakty sekretów: referencje, procedury rotacji, schematy, szablony. NIGDY nie zawiera rzeczywistych sekretów.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji sekretów. Vault/Runtime odzwierciedla actual state.

## 4. Contains
Referencje sekretów, procedury rotacji, schematy, szablony, polityki.

## 5. Does Not Contain
NIE zawiera rzeczywistych sekretów, kluczy, tokenów ani haseł. Tylko referencje i szablony.

## 6. Dependencies
Zależy od security, governance, config.

## 7. Consumers
Operatorzy, Vault, narzędzia bezpieczeństwa.

## 8. Synchronization
Klasa: `CANONICAL` — definicje sekretów są źródłem prawdy w git. Rzeczywiste sekrety w Vault.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. NIGDY nie przechowuje rzeczywistych sekretów w git — tylko referencje i szablony.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania sekretów.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami sekretów (git) a faktycznym stanem (Vault). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
