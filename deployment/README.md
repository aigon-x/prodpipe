# deployment

> Katalog wdrożeniowy AIGON Production Platform — rings, profiles, images, manifests, terraform.

## 1. Purpose
Przechowuje artefakty wdrożeniowe: rings, profiles, images, manifests, helm, terraform, scripts.

## 2. Owner
`STATUS: FOUNDATION PLACEHOLDER`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji wdrożeniowych. Runtime odzwierciedla actual state.

## 4. Contains
Rings, profiles, images, manifests, helm, terraform, scripts, secrets, backup, restore.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state.

## 6. Dependencies
Zależy od config, artifacts, tools.

## 7. Consumers
Narzędzia wdrożeniowe, CI/CD, operatorzy.

## 8. Synchronization
Klasa: `CANONICAL` — definicje wdrożeniowe są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: FOUNDATION PLACEHOLDER`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko definicje i referencje.

## 11. Recovery
`STATUS: FOUNDATION PLACEHOLDER` — procedury odzyskiwania wdrożeń.

## 12. Drift Detection
Wykrywanie rozjazdu między definicjami wdrożeniowymi (git) a faktycznym stanem (Runtime). `STATUS: FOUNDATION PLACEHOLDER`.

## Examples
`STATUS: FOUNDATION PLACEHOLDER`
