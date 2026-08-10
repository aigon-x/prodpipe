# testing

> Współdzielony framework testowy platformy — runner oraz narzędzia do pokrycia, jakości, regresji i raportowania.

## 1. Purpose
Współdzielony framework testowy platformy, który dostarcza runner oraz narzędzia do wykrywania testów, pomiaru pokrycia, oceny jakości, testów regresyjnych i generowania raportów. Celem jest ujednolicenie i automatyzacja procesu testowania w całej platformie.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Standardy testowania, wymagania jakościowe i konwencje raportowania są zdefiniowane w dokumentacji platformy oraz w konfiguracji narzędzi. Framework jest wykonawcą tych standardów, nie ich źródłem.

## 4. Contains
- `runner.sh` — główny runner uruchamiający testy platformy.
- `discovery.sh` — wykrywanie i enumeracja testów w repozytorium.
- `coverage.sh` — pomiar pokrycia kodu testami.
- `quality.sh` — ocena jakości kodu i testów.
- `regression.sh` — uruchamianie testów regresyjnych.
- `manifest.sh` — zarządzanie manifestem testów.
- `report.sh` — generowanie raportów z wyników testów.
- `lib.sh` — biblioteka współdzielonych funkcji pomocniczych.

## 5. Does Not Contain
Nie zawiera samych testów poszczególnych modułów (te żyją w katalogach modułów) ani danych produkcyjnych. Nie zawiera też narzędzi scaffolding ani narzędzi weryfikacji struktury repozytorium.

## 6. Dependencies
Zależy od środowiska wykonawczego (bash, narzędzia testowe, narzędzia pokrycia) oraz od struktury testów w repozytorium. Skrypty współdzielą funkcje z `lib.sh` i mogą wymagać narzędzi zewnętrznych do pomiaru pokrycia i jakości.

## 7. Consumers
Wszystkie moduły platformy oraz pipeline CI/CD, które używają frameworku do uruchamiania testów i generowania raportów. Programiści korzystają z niego do lokalnego uruchamiania testów.

## 8. Synchronization
Framework musi być synchronizowany ze standardami testowania i strukturą repozytorium. Zmiany w konwencjach testów lub dodanie nowych modułów wymagają aktualizacji narzędzi wykrywania i manifestu.

## 9. Lifecycle
Framework jest rozwijany wraz z platformą; nowe narzędzia i funkcje są dodawane w miarę potrzeb. Wersjonowanie i zmiany są śledzone w kontroli wersji repozytorium.

## 10. Security
Skrypty uruchamiają testy w środowisku wykonawczym i nie powinny mieć dostępu do danych produkcyjnych ani sekretów. Wrażliwe dane uwierzytelniające nie powinny być przechowywane w frameworku.

## 11. Recovery
Framework jest częścią repozytorium i można go odtworzyć z kontroli wersji. W razie awarii środowiska testowego testy można uruchomić ponownie w czystym środowisku.

## 12. Drift Detection
Zgodność frameworku ze standardami testowania i strukturą repozytorium jest weryfikowana przez certyfikację struktury repozytorium oraz przez uruchamianie testów w CI/CD. Rozbieżności sygnalizują potrzebę aktualizacji narzędzi.
