# code

> Automatyzacja jakości kodu — testy, lint, formatowanie, przeglądy i analiza wydajności.

## 1. Purpose
Automatyzuje kontrolę jakości kodu: uruchamianie testów jednostkowych, integracyjnych i E2E, lintowanie, formatowanie, analizę pokrycia, wydajności oraz przeglądy kodu.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Konfiguracje narzędzi jakości (lint, format, testy) oraz standardy kodowania zdefiniowane w repozytorium.

## 4. Contains
Skrypty powłoki: coverage.sh, e2e-tests.sh, format.sh, integration-tests.sh, lint.sh, performance.sh, review.sh, unit-tests.sh.

## 5. Does Not Contain
Nie zawiera samych testów ani konfiguracji narzędzi — wyłącznie orkiestrację ich uruchamiania. Nie zawiera logiki biznesowej aplikacji.

## 6. Dependencies
Wymaga zainstalowanych narzędzi jakości kodu (runner testów, linter, formatter) oraz środowiska budowania projektu.

## 7. Consumers
Pipeline'y CI/CD, deweloperzy, procesy przeglądu kodu i bramki jakości przed wdrożeniem.

## 8. Synchronization
Skrypty synchronizowane z repozytorium przez standardowy mechanizm dystrybucji narzędzi automatyzacji.

## 9. Lifecycle
Ewoluują wraz ze stosem narzędzi jakości; wersjonowane w git, aktualizowane przy zmianie narzędzi lub standardów.

## 10. Security
Skrypty nie przechowują sekretów; uruchamiane w izolowanym środowisku CI z ograniczonymi uprawnieniami.

## 11. Recovery
W razie błędu skrypt można uruchomić ponownie; wyniki testów i logi są przechowywane jako artefakty CI.

## 12. Drift Detection
Rozbieżności między lokalną wersją skryptów a wersją w repozytorium są wykrywane przez mechanizm certyfikacji.
