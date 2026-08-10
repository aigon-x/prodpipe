# SEC-DEPLOY — Confidentiality Drills (domena: confidentiality)

## Cel
Fire drills z domeny **confidentiality** weryfikują, że dane poufne są chronione:
brak ekspozycji sekretów, brak wycieków pamięci, brak wycieków między tenantami
i brak eksfiltracji danych. Celem jest udowodnienie, że warstwa poufności
faktycznie chroni dane przed nieautoryzowanym ujawnieniem.

## Przykładowe wtryski
- `inject-secret-exposure.sh` — symulacja ekspozycji sekretu.
- `inject-memory-leak.sh` — symulacja wycieku pamięci (dane w logach/dumpach).
- `inject-cross-tenant.sh` — symulacja wycieku między tenantami.
- `inject-exfiltration.sh` — symulacja eksfiltracji danych.

## Jak uruchomić
Wtryski są uruchamiane przez pipeline SEC-DEPLOY (`tools/verify/security/drills.sh`).
Każdy wtrysk to skrypt `inject-*.sh` w tym katalogu, uruchamiany w fazie INJECT.
Detekcja to skrypt `detect.sh` uruchamiany w fazie DETECT.

## OCZEKIWANY WYNIK
Żadne dane poufne NIE mogą zostać ujawnione poza dozwolony kontekst. Wykrycie
ekspozycji sekretu, wycieku pamięci, wycieku między tenantami lub eksfiltracji
= FAIL (BLOCKING) — poufność, która przecieka, jest martwa.

## DESTROY
Po zakończeniu testu wtrysk MUSI zostać usunięty, aby nie pozostawić śladów
w środowisku produkcyjnym. Usuń pliki `inject-*.sh`, wycofaj zmiany w konfiguracji
i zweryfikuj, że środowisko wróciło do stanu sprzed testu.
