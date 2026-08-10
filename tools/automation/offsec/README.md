# offsec

> Automatyzacja bezpieczeństwa ofensywnego — rozpoznanie, eksploitacja, utrzymanie dostępu i remediacja.

## 1. Purpose
Automatyzuje działania bezpieczeństwa ofensywnego: rozpoznanie, skanowanie, wykrywanie, eksploitację, utrzymanie dostępu, naukę oraz remediację i reagowanie na incydenty.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Zakres autoryzowanych testów i polityki bezpieczeństwa zdefiniowane w repozytorium są źródłem prawdy dla działań ofensywnych.

## 4. Contains
Skrypty powłoki: detect.sh, exfil.sh, exploit.sh, learn.sh, persist.sh, recon.sh, remediate.sh, respond.sh, scan.sh.

## 5. Does Not Contain
Nie zawiera narzędzi ani exploitów — wyłącznie orkiestrację procesów bezpieczeństwa ofensywnego w autoryzowanym zakresie.

## 6. Dependencies
Wymaga narzędzi bezpieczeństwa ofensywnego oraz autoryzowanego dostępu do testowanych systemów.

## 7. Consumers
Zespoły bezpieczeństwa, procesy testów penetracyjnych i reagowania na incydenty.

## 8. Synchronization
Skrypty synchronizowane z repozytorium przez standardowy mechanizm dystrybucji narzędzi automatyzacji.

## 9. Lifecycle
Ewoluują wraz z taktykami bezpieczeństwa; wersjonowane w git, aktualizowane przy zmianie zakresu autoryzacji.

## 10. Security
Skrypty działają wyłącznie w autoryzowanym zakresie; nie przechowują sekretów ani danych wrażliwych.

## 11. Recovery
W razie awarii skrypty można uruchomić ponownie; wyniki działań są rejestrowane w logach audytowych.

## 12. Drift Detection
Rozbieżności między skryptami a wersją w repozytorium są wykrywane przez mechanizm certyfikacji.
