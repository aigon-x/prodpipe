# alerts

> Kanoniczne definicje alertów platformy AIGON — wzorzec szablonu alertu.

## 1. Purpose
Przechowuje kanoniczne definicje alertów używanych w platformie AIGON. Stanowi wzorzec (template) dla wszystkich alertów systemowych.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Plik `_template.yaml` w tym katalogu jest źródłem prawdy dla struktury i pól kanonicznego alertu.

## 4. Contains
- `_template.yaml` — szablon definicji alertu (alert template) określający wymagane pola i strukturę.

## 5. Does Not Contain
Nie zawiera konkretnych instancji alertów ani logiki generowania alertów — wyłącznie wzorzec definicyjny.

## 6. Dependencies
Zależy od konwencji konfiguracyjnych platformy oraz od systemów monitorowania, które konsumują definicje alertów.

## 7. Consumers
Moduły monitorowania i powiadamiania platformy AIGON, które tworzą i obsługują alerty na podstawie tego szablonu.

## 8. Synchronization
Zmiany szablonu są synchronizowane z repozytorium i propagowane do systemów konsumujących definicje alertów.

## 9. Lifecycle
Szablon ewoluuje wraz z wymaganiami monitorowania; zmiany wymagają przeglądu i zatwierdzenia.

## 10. Security
Plik nie zawiera sekretów; podlegają standardowym zasadom kontroli dostępu repozytorium.

## 11. Recovery
W przypadku utraty pliku można go odtworzyć z historii repozytorium (git) lub z certyfikowanej kopii zapasowej.

## 12. Drift Detection
Obecność tego README oraz zgodność struktury katalogu jest weryfikowana przez silnik certyfikacji struktury (tools/verify/structure).
