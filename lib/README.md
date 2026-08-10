# lib

> Współdzielona biblioteka platformy AIGON — narzędzia pomocnicze, w tym biblioteka logowania.

## 1. Purpose
Przechowuje współdzielone biblioteki i narzędzia pomocnicze używane przez różne moduły platformy AIGON. Zawiera m.in. współdzieloną bibliotekę logowania.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Pliki w tym katalogu (np. `log.sh`) są źródłem prawdy dla współdzielonych funkcji pomocniczych.

## 4. Contains
- `log.sh` — współdzielona biblioteka logowania (shared logging library).

## 5. Does Not Contain
Nie zawiera logiki biznesowej ani konfiguracji specyficznej dla pojedynczych modułów — wyłącznie współdzielone narzędzia.

## 6. Dependencies
Zależy od środowiska wykonawczego (shell) oraz od konwencji platformy dotyczących logowania.

## 7. Consumers
Wszystkie moduły i skrypty platformy AIGON, które korzystają ze współdzielonych funkcji logowania.

## 8. Synchronization
Zmiany w bibliotece są synchronizowane z repozytorium i propagowane do wszystkich konsumentów.

## 9. Lifecycle
Biblioteka ewoluuje wraz z platformą; zmiany wymagają przeglądu i testów przed wdrożeniem.

## 10. Security
Pliki nie zawierają sekretów; podlegają standardowym zasadom kontroli dostępu repozytorium.

## 11. Recovery
W przypadku utraty plików można je odtworzyć z historii repozytorium (git) lub z certyfikowanej kopii zapasowej.

## 12. Drift Detection
Obecność tego README oraz zgodność struktury katalogu jest weryfikowana przez silnik certyfikacji struktury (tools/verify/structure).
