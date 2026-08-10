# restore-drill

> Automatyzacja cyklicznych prób przywracania (restore drill) mających udowodnić, że odzyskiwanie RTO/RPO działa end-to-end.

## 1. Purpose
Zautomatyzowane, cykliczne próby przywracania (restore drill), które weryfikują end-to-end, że procedury odzyskiwania spełniają cele RTO/RPO. Celem jest udowodnienie, że kopie zapasowe są realnie przywracalne, a nie tylko tworzone.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Definicja celów RTO/RPO oraz procedur odzyskiwania znajduje się w dokumentacji platformy (RECOVERY.md / SOURCE-OF-TRUTH.md) w katalogu głównym repozytorium. Skrypty w tym katalogu są wykonawcą, nie źródłem definicji celów.

## 4. Contains
- `restore-drill.sh` — skrypt wykonujący pełną próbę przywracania (restore drill) i raportujący wynik.
- `restore-drill.cron` — wpis crontab planujący cykliczne uruchamianie próby przywracania.

## 5. Does Not Contain
Nie zawiera samych kopii zapasowych ani danych do przywrócenia — te żyją w systemach backupowych. Nie zawiera też definicji polityk RTO/RPO ani pełnej dokumentacji procedur odzyskiwania.

## 6. Dependencies
Zależy od działającego systemu backup/restore platformy oraz od narzędzi dostępnych w środowisku wykonawczym (cron, powłoka bash). Wymaga uprawnień niezbędnych do uruchomienia przywracania w środowisku docelowym.

## 7. Consumers
Operatorzy i inżynierowie odpowiedzialni za ciągłość działania (HA/DR), którzy analizują raporty z prób przywracania. Wyniki mogą być konsumowane przez narzędzia monitorujące i raportujące platformy.

## 8. Synchronization
Skrypt i wpis cron muszą być synchronizowane z aktualnymi procedurami odzyskiwania oraz z konfiguracją systemu backupowego. Zmiany w celach RTO/RPO wymagają aktualizacji parametrów próby przywracania.

## 9. Lifecycle
Próby przywracania uruchamiane są cyklicznie zgodnie z harmonogramem cron. Wyniki każdej próby są raportowane i archiwizowane; nieudane próby wymagają eskalacji i naprawy.

## 10. Security
Skrypt może wymagać dostępu do wrażliwych danych i systemów backupowych. Dostęp do katalogu i uruchamianie prób powinny być ograniczone do uprawnionych operatorów, a dane uwierzytelniające nie powinny być przechowywane w repozytorium.

## 11. Recovery
Sam katalog nie wymaga odzyskiwania — jest częścią repozytorium. Jego zadaniem jest weryfikacja odzyskiwania platformy; w razie awarii skrypt można odtworzyć z kontroli wersji.

## 12. Drift Detection
Zgodność skryptu z aktualnymi procedurami odzyskiwania i celami RTO/RPO jest weryfikowana przez certyfikację struktury repozytorium oraz przegląd wyników prób przywracania.
