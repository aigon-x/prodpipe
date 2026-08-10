# core

> Silnik pipeline'ów — generuje pipelines.sh z pipelines.yaml oraz dostarcza wspólne biblioteki.

## 1. Purpose
Stanowi rdzeń silnika pipeline'ów: generuje pipelines.sh na podstawie deklaratywnej konfiguracji pipelines.yaml oraz dostarcza wspólne funkcje biblioteczne (lib.sh) używane przez pozostałe skrypty automatyzacji.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Definicje pipeline'ów w pliku pipelines.yaml oraz wspólne funkcje w lib.sh są źródłem prawdy dla generowanych artefaktów.

## 4. Contains
Skrypty powłoki: gen-pipelines.sh (generator), lib.sh (biblioteka wspólna), pipelines.sh (wygenerowany artefakt).

## 5. Does Not Contain
Nie zawiera logiki specyficznej dla pojedynczych domen automatyzacji (AI, security itd.) — wyłącznie mechanizm generowania i współdzielone funkcje.

## 6. Dependencies
Wymaga interpretera powłoki oraz narzędzi do przetwarzania YAML. pipelines.sh zależy od lib.sh.

## 7. Consumers
Wszystkie pozostałe skrypty automatyzacji w tools/automation oraz pipeline'y CI/CD.

## 8. Synchronization
pipelines.sh jest regenerowany z pipelines.yaml przez gen-pipelines.sh; zmiany w konfiguracji wymagają ponownego wygenerowania.

## 9. Lifecycle
Generator i biblioteka ewoluują wraz z architekturą pipeline'ów; wersjonowane w git.

## 10. Security
Skrypty nie przechowują sekretów; pipelines.yaml może zawierać referencje do sekretów zarządzanych zewnętrznie.

## 11. Recovery
Wygenerowany pipelines.sh można odtworzyć przez ponowne uruchomienie gen-pipelines.sh z pipelines.yaml.

## 12. Drift Detection
Rozbieżność między pipelines.yaml a wygenerowanym pipelines.sh jest wykrywana przez porównanie wyników generatora z wersją w repozytorium.
