# backup

> Katalog dla definicji backupów AIGON Production Platform — polityki i procedury tworzenia kopii zapasowych.

## 1. Purpose
Przechowuje definicje backupów — polityki, procedury i konfigurację tworzenia kopii zapasowych.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla definicji backupów. Runtime odzwierciedla actual state wykonanych backupów.

## 4. Contains
Polityki backupów, procedury, konfiguracja tworzenia kopii zapasowych, harmonogramy.

## 5. Does Not Contain
Nie zawiera samych kopii zapasowych (te żyją w magazynie backupów), sekretów ani runtime state.

## 6. Dependencies
Zależy od magazynu backupów oraz deployment/manifests, deployment/restore.

## 7. Consumers
Narzędzia operacyjne, orkiestrator, pipeline wdrożeniowy.

## 8. Synchronization
Klasa: `CANONICAL` — definicje backupów są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko schematy i polityki.

## 11. Recovery
Odzyskiwanie opiera się na wykonanych backupach zgodnie z politykami zdefiniowanymi w tym katalogu.

## 12. Drift Detection
Wykrywanie rozjazdu między politykami backupów (git) a faktycznie wykonanymi backupami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
