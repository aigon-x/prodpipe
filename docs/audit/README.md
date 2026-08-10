# audit

> Dokumentacja audytów platformy AIGON — raporty audytowe i dokumentacja pakietu sondy.

## 1. Purpose
Przechowuje dokumentację audytową platformy AIGON, w tym raporty audytowe oraz dokumentację pakietu sondy (probe package).

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Pliki w tym katalogu (`audyt-v1.md`, `sonda-package.md`) są źródłem prawdy dla udokumentowanych wyników audytów.

## 4. Contains
- `audyt-v1.md` — raport audytu wersji 1 (audit report).
- `sonda-package.md` — dokumentacja pakietu sondy (probe package docs).

## 5. Does Not Contain
Nie zawiera narzędzi audytowych ani logiki wykonawczej — wyłącznie dokumentacja i raporty.

## 6. Dependencies
Zależy od wyników procesów audytowych oraz od narzędzi używanych do przeprowadzania audytów w platformie.

## 7. Consumers
Zespoły audytowe, inżynierowie platformy oraz procesy certyfikacji korzystające z udokumentowanych wyników audytów.

## 8. Synchronization
Dokumentacja jest synchronizowana z repozytorium i aktualizowana po każdym przeprowadzonym audycie.

## 9. Lifecycle
Raporty audytowe są archiwizowane i aktualizowane wraz z kolejnymi wersjami audytów platformy.

## 10. Security
Dokumentacja może zawierać informacje wrażliwe dotyczące systemu; podlega standardowym zasadom kontroli dostępu repozytorium.

## 11. Recovery
W przypadku utraty dokumentacji można ją odtworzyć z historii repozytorium (git) lub z certyfikowanej kopii zapasowej.

## 12. Drift Detection
Obecność tego README oraz zgodność struktury katalogu jest weryfikowana przez silnik certyfikacji struktury (tools/verify/structure).
