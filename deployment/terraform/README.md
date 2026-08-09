# terraform

> Katalog dla konfiguracji Terraform AIGON Production Platform — infrastruktura jako kod (IaC).

## 1. Purpose
Przechowuje konfigurację Terraform — deklaratywne definicje infrastruktury (IaC).

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla konfiguracji Terraform. Runtime odzwierciedla actual state infrastruktury.

## 4. Contains
Konfiguracja Terraform, moduły, definicje infrastruktury, pliki stanu (state) — referencje.

## 5. Does Not Contain
Nie zawiera sekretów ani runtime state (stan Terraform żyje w backendzie, nie w git).

## 6. Dependencies
Zależy od providerów chmurowych oraz deployment/rings, deployment/profiles.

## 7. Consumers
Pipeline wdrożeniowy, orkiestrator, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CANONICAL` — konfiguracja Terraform jest źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i referencje.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania konfiguracji Terraform.

## 12. Drift Detection
Wykrywanie rozjazdu między konfiguracją Terraform (git) a faktyczną infrastrukturą (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
