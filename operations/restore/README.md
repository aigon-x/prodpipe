# restore

> Katalog dla procedur przywracania operacyjnego AIGON Production Platform — odzyskiwanie z backupów.

## 1. Purpose
Przechowuje procedury przywracania operacyjnego — odzyskiwanie danych i stanu z backupów.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git jest źródłem prawdy (desired state) dla procedur przywracania. Runtime odzwierciedla actual state wykonanych przywróceń.

## 4. Contains
Procedury przywracania, konfiguracja odzyskiwania, harmonogramy testów przywracania.

## 5. Does Not Contain
Nie zawiera samych kopii zapasowych, sekretów ani runtime state.

## 6. Dependencies
Zależy od operations/backup oraz magazynu backupów.

## 7. Consumers
Operatorzy, narzędzia operacyjne, orkiestrator.

## 8. Synchronization
Klasa: `CANONICAL` — procedury przywracania są źródłem prawdy w git.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Brak sekretów w git — tylko procedury i harmonogramy.

## 11. Recovery
Ten katalog definiuje procedury odzyskiwania danych z backupów.

## 12. Drift Detection
Wykrywanie rozjazdu między procedurami przywracania (git) a faktycznie wykonanymi przywróceniami (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
