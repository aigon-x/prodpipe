# aesthetics

> Konfiguracja jakości i estetyki kodu — wagi indeksu jakości, reguły spektralne i definicje golden path.

## 1. Purpose
Definiuje parametry jakościowe i estetyczne używane do oceny kodu w platformie AIGON. Zawiera wagi indeksu jakości (QI), reguły spektralne oraz definicje golden path.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Pliki YAML w tym katalogu (`golden-path.yaml`, `qi-weights.yaml`, `spectral-rules.yaml`) są źródłem prawdy dla konfiguracji jakości i estetyki.

## 4. Contains
- `golden-path.yaml` — definicje ścieżek golden path (wzorców zalecanych).
- `qi-weights.yaml` — wagi indeksu jakości (quality index weights).
- `spectral-rules.yaml` — reguły spektralne (spectral rules) dla analizy kodu.

## 5. Does Not Contain
Nie zawiera logiki wykonawczej, skryptów ani narzędzi analitycznych — wyłącznie dane konfiguracyjne w formacie YAML.

## 6. Dependencies
Zależy od schematów i konwencji konfiguracyjnych platformy AIGON oraz od narzędzi, które odczytują te pliki (np. silnik oceny jakości).

## 7. Consumers
Narzędzia i moduły platformy odpowiedzialne za ocenę jakości kodu, analizę spektralną oraz walidację zgodności z golden path.

## 8. Synchronization
Zmiany w plikach konfiguracyjnych są synchronizowane z repozytorium i propagowane do konsumentów zgodnie z procesem wdrożeniowym platformy.

## 9. Lifecycle
Konfiguracja ewoluuje wraz z platformą; zmiany wag i reguł wymagają przeglądu i zatwierdzenia przed wdrożeniem.

## 10. Security
Pliki nie zawierają sekretów ani danych wrażliwych; podlegają standardowym zasadom kontroli dostępu repozytorium.

## 11. Recovery
W przypadku uszkodzenia lub utraty plików można je odtworzyć z historii repozytorium (git) lub z certyfikowanej kopii zapasowej.

## 12. Drift Detection
Zgodność plików ze stanem oczekiwanym jest weryfikowana przez silnik certyfikacji struktury (tools/verify/structure), który wymaga obecności tego README.
