# SEC-DEPLOY — Authorization Drills (domena: authorization)

## Cel
Fire drills z domeny **authorization** weryfikują, że kontrola dostępu jest
szczelna: brak eskalacji uprawnień, brak bypassu polityk, brak confused deputy
i brak złamania łańcucha autoryzacji. Celem jest udowodnienie, że zasady
RBAC/ABAC faktycznie egzekwują granice uprawnień.

## Przykładowe wtryski
- `inject-privilege-escalation.sh` — próba eskalacji uprawnień.
- `inject-policy-bypass.sh` — próba obejścia polityki dostępu.
- `inject-confused-deputy.sh` — atak confused deputy (podmiana kontekstu).
- `inject-authority-chain.sh` — złamanie łańcucha autoryzacji.

## Jak uruchomić
Wtryski są uruchamiane przez pipeline SEC-DEPLOY (`tools/verify/security/drills.sh`).
Każdy wtrysk to skrypt `inject-*.sh` w tym katalogu, uruchamiany w fazie INJECT.
Detekcja to skrypt `detect.sh` uruchamiany w fazie DETECT.

## OCZEKIWANY WYNIK
Każda próba eskalacji/bypassu MUSI zostać zablokowana przez warstwę autoryzacji
i odnotowana w logu audytowym. Zezwolenie na nieautoryzowaną operację = FAIL
(BLOCKING) — autoryzacja, która przepuszcza, jest martwa.

## DESTROY
Po zakończeniu testu wtrysk MUSI zostać usunięty, aby nie pozostawić śladów
w środowisku produkcyjnym. Usuń pliki `inject-*.sh`, wycofaj zmiany w konfiguracji
i zweryfikuj, że środowisko wróciło do stanu sprzed testu.
