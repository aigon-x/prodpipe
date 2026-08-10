# tests

> Testy narzędzia scaffolding (tools/scaffold) weryfikujące poprawność generowania nowych komponentów platformy.

## 1. Purpose
Testy automatyczne dla narzędzia scaffolding, które weryfikują, że generowane struktury, pliki i konfiguracje są poprawne i zgodne z wymaganiami platformy. Celem jest wykrycie regresji w narzędziu szkieletującym nowe komponenty.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Wymagania dotyczące struktury generowanych komponentów oraz zachowania narzędzia scaffolding są zdefiniowane w dokumentacji narzędzia tools/scaffold oraz w konwencjach repozytorium. Testy odzwierciedlają te wymagania.

## 4. Contains
- `test-scaffold.sh` — skrypt testowy uruchamiający zestaw testów narzędzia scaffolding i raportujący wyniki.

## 5. Does Not Contain
Nie zawiera samego narzędzia scaffolding (to znajduje się w katalogu nadrzędnym tools/scaffold) ani danych produkcyjnych. Nie zawiera też testów innych narzędzi platformy.

## 6. Dependencies
Zależy od narzędzia scaffolding (tools/scaffold), które jest przedmiotem testów, oraz od środowiska wykonawczego (bash, narzędzia testowe). Wymaga dostępu do katalogu roboczego do generowania struktur testowych.

## 7. Consumers
Programiści i inżynierowie rozwijający narzędzie scaffolding oraz pipeline CI/CD, który uruchamia testy przy każdej zmianie. Wyniki testów potwierdzają, że szkieletowanie działa poprawnie.

## 8. Synchronization
Testy muszą być synchronizowane ze zmianami w narzędziu scaffolding — każda zmiana zachowania lub struktury generowanych komponentów wymaga aktualizacji testów. Testy uruchamiane są w pipeline CI/CD.

## 9. Lifecycle
Testy uruchamiane są automatycznie w pipeline CI/CD oraz ręcznie podczas rozwoju. Wyniki są raportowane; nieudane testy blokują wdrożenie zmian w narzędziu scaffolding.

## 10. Security
Testy generują struktury w środowisku testowym i nie powinny mieć dostępu do danych produkcyjnych ani sekretów. Skrypt nie powinien zawierać wrażliwych danych uwierzytelniających.

## 11. Recovery
Katalog jest częścią repozytorium i można go odtworzyć z kontroli wersji. W razie awarii środowiska testowego testy można uruchomić ponownie w czystym środowisku.

## 12. Drift Detection
Zgodność testów z aktualnym zachowaniem narzędzia scaffolding jest weryfikowana przez uruchamianie testów w CI/CD oraz przez certyfikację struktury repozytorium. Rozbieżności sygnalizują potrzebę aktualizacji testów.
