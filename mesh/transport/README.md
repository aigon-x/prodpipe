# transport

> Katalog mesh przechowujący artefakty warstwy transportu — deklaracje i konfigurację komunikacji między nodami.

## 1. Purpose
Przechowywanie artefaktów warstwy transportu mesh — deklaracji i konfiguracji komunikacji między nodami.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny mesh nie jest jeszcze przypisany.

## 3. Source of Truth
Git = desired state (deklaracje / konfiguracja), Runtime = actual state (stan faktyczny połączeń).

## 4. Contains
Artefakty warstwy transportu: deklaracje, konfiguracja komunikacji między nodami.

## 5. Does Not Contain
- Dane runtime'owe (to domena AIGON-X-FS).
- Sekrety (tylko schematy/templates/referencje/polityki rotacji).
- Drugi Source of Truth.

## 6. Dependencies
Mesh (katalog nadrzędny), warstwa security (szyfrowanie transportu).

## 7. Consumers
Runtime, komponenty mesh, warstwa transportu. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `CANONICAL` / `REPLICATED`. Konfiguracja transportu jest kanoniczna i replikowana. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia artefaktów transportu nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja: konfiguracja transportu. Zakaz sekretów. Wymagane szyfrowanie komunikacji.

## 11. Recovery
Odzyskiwanie z Git (desired state) / replik. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
Porównanie stanu faktycznego (Runtime) ze stanem pożądanym (Git). `STATUS: ARCHITECTURAL GAP` dla mechanizmu.

## Examples
`STATUS: UNDEFINED`.
