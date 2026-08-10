# scaffold

> Szkielet (scaffold) kontraktów platformy AIGON — wzorzec dokumentu kontraktu.

## 1. Purpose
Dostarcza szablon (scaffold) do tworzenia nowych kontraktów w platformie AIGON. Określa strukturę i wymagane sekcje dokumentu kontraktu.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Plik `contract.md` w tym katalogu jest źródłem prawdy dla struktury dokumentu kontraktu.

## 4. Contains
- `contract.md` — szablon/szkielet dokumentu kontraktu (contract template/scaffold).

## 5. Does Not Contain
Nie zawiera treści konkretnych kontraktów ani logiki walidacji kontraktów — wyłącznie wzorzec strukturalny.

## 6. Dependencies
Zależy od konwencji dokumentacyjnych platformy oraz od procesów tworzenia i zatwierdzania kontraktów.

## 7. Consumers
Autorzy kontraktów oraz narzędzia walidujące strukturę dokumentów kontraktowych w platformie AIGON.

## 8. Synchronization
Zmiany szablonu są synchronizowane z repozytorium i propagowane do procesów tworzenia kontraktów.

## 9. Lifecycle
Szablon ewoluuje wraz z wymaganiami kontraktowymi; zmiany wymagają przeglądu i zatwierdzenia.

## 10. Security
Plik nie zawiera sekretów; podlegają standardowym zasadom kontroli dostępu repozytorium.

## 11. Recovery
W przypadku utraty pliku można go odtworzyć z historii repozytorium (git) lub z certyfikowanej kopii zapasowej.

## 12. Drift Detection
Obecność tego README oraz zgodność struktury katalogu jest weryfikowana przez silnik certyfikacji struktury (tools/verify/structure).
