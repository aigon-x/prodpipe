# SEC-DEPLOY — Detection Drills (domena: detection)

## Cel
Fire drills z domeny **detection** weryfikują, że platforma potrafi **wykryć**
intruzję, anomalie i kompromitację zanim wyrządzą szkodę. Celem jest udowodnienie,
że warstwa detekcji (logi, metryki, alerty, SIEM, EDR) faktycznie reaguje na
symulowane zdarzenia — a nie tylko istnieje na papierze.

## Przykładowe wtryski
- `inject-intrusion.sh` — symulacja nieautoryzowanego logowania / brute-force.
- `inject-anomaly.sh` — nietypowy ruch sieciowy / anomalia metryk.
- `inject-compromise.sh` — symulacja kompromitacji konta / procesu.

## Jak uruchomić
Wtryski są uruchamiane przez pipeline SEC-DEPLOY (`tools/verify/security/drills.sh`).
Każdy wtrysk to skrypt `inject-*.sh` w tym katalogu, uruchamiany w fazie INJECT.
Detekcja to skrypt `detect.sh` uruchamiany w fazie DETECT.

## OCZEKIWANY WYNIK
Po wstrzyknięciu symulowanego zdarzenia warstwa detekcji MUSI wygenerować alert
lub wpis w logu identyfikujący zdarzenie. Brak wykrycia = FAIL (BLOCKING) —
detekcja, która nie wykrywa, jest martwa.

## DESTROY
Po zakończeniu testu wtrysk MUSI zostać usunięty, aby nie pozostawić śladów
w środowisku produkcyjnym. Usuń pliki `inject-*.sh`, wycofaj zmiany w konfiguracji
i zweryfikuj, że środowisko wróciło do stanu sprzed testu.
