# SEC-DEPLOY — Recovery Drills (domena: recovery)

## Cel
Fire drills z domeny **recovery** weryfikują, że platforma potrafi **odzyskać**
się po incydencie: odtworzenie poświadczeń, nodów, serwisów i pełne odzyskanie
po incydencie. Celem jest udowodnienie, że procedury disaster recovery i
failover faktycznie działają pod obciążeniem incydentu.

## Przykładowe wtryski
- `inject-credential-loss.sh` — symulacja utraty/rotacji poświadczeń.
- `inject-node-failure.sh` — symulacja awarii noda.
- `inject-service-down.sh` — symulacja upadku serwisu.
- `inject-incident.sh` — symulacja pełnego incydentu.

## Jak uruchomić
Wtryski są uruchamiane przez pipeline SEC-DEPLOY (`tools/verify/security/drills.sh`).
Każdy wtrysk to skrypt `inject-*.sh` w tym katalogu, uruchamiany w fazie INJECT.
Detekcja to skrypt `detect.sh` uruchamiany w fazie DETECT.

## OCZEKIWANY WYNIK
Po wstrzyknięciu awarii system MUSI odzyskać sprawność w zdefiniowanym czasie
(RTO/RPO) i przywrócić pełną funkcjonalność. Brak odzyskania = FAIL (BLOCKING) —
recovery, które nie odzyskuje, jest martwe.

## DESTROY
Po zakończeniu testu wtrysk MUSI zostać usunięty, aby nie pozostawić śladów
w środowisku produkcyjnym. Usuń pliki `inject-*.sh`, wycofaj zmiany w konfiguracji
i zweryfikuj, że środowisko wróciło do stanu sprzed testu.
