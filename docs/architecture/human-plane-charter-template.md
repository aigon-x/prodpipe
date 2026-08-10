# HUMAN PLANE — Charter Template + Format Evidence Sesji Eksploracyjnej

> Design doc — deliverable (a) HUMAN PLANE: pełny template charteru + format evidence sesji eksploracyjnej.
> Status: DESIGN (do implementacji). Operacjonalizuje MAN-01, MAN-02, MAN-03, MAN-08.

## Cel

Ten dokument to **gotowy do użycia szablon** dla trzech artefaktów, które czynią człowieka *oracle* w zgatedowanym procesie:

1. **Charter** (MAN-01/02) — udokumentowana, ograniczona misja eksploracyjna. Odpowiada na pytanie *co i dlaczego sprawdzamy*.
2. **Evidence sesji eksploracyjnej** (MAN-02/08) — dowód, że sesja faktycznie się odbyła, z pełnym śladem. Odpowiada na pytanie *co zrobiono i co znaleziono*.
3. **UAT sign-off** (MAN-03) — akceptacja podpisana na **konkretny digest artefaktu**, nie "wersję ogólnie". Odpowiada na pytanie *kto i na co dokładnie się zgodził*.

Dwie zasady kanoniczne HUMAN PLANE (z `human-plane-design.md`):

> **Aktywność manualna bez evidence = nie odbyła się.**
> **Evidence manualne bez świeżości = nieważne.**

Charter bez evidence to deklaracja. Evidence bez charteru to chaos. Sign-off bez digesta to podpis w powietrzu.

---

## Część 1 — Template charteru (MAN-01/02)

Charter to **misja eksploracyjna z granicami**: wiemy, co sprawdzamy, czego nie sprawdzamy, ile mamy czasu i kiedy uznajemy misję za zrealizowaną. To nie jest "przetestuj wszystko" — to jest *bounded exploration*.

```yaml
charter_id:        CH-<service>-<NNN>          # np. CH-auth-001
service_id:        <id serwisu>                # np. auth-service
journey_id:        <ścieżka użytkownika>       # np. JRN-login-sso
tier:              <0|1|2>                     # tier releasu (MAN-04/05: rytm i świeżość zależą od tieru)
coverage_type:     AUTO | MANUAL               # MAN-01: AUTO = pokryty testem auto, MANUAL = charter
title:             <imperatyw, np. "Zaloguj się przez SSO">
mission:           <co dokładnie sprawdzamy — BOUNDED, nie "przetestuj wszystko">
scope:             <co jest w zakresie>
out_of_scope:      <co NIE jest w zakresie — równie ważne jak scope>
preconditions:     <dane, stan, środowisko — co musi być gotowe przed startem>
test_ideas:        <konkretne przypadki do sprawdzenia — POMYSŁY, nie kroki>
timebox:           <np. 45 min>
owner:             <kto prowadzi charter>
created_at:        <YYYY-MM-DD>
status:            ACTIVE | COMPLETED | ARCHIVED
acceptance_criteria: <kiedy charter uznany za zrealizowany — mierzalne>
```

### Reguły wypełniania

- **`mission` musi być bounded.** "Sprawdź logowanie" to nie misja. "Sprawdź, czy użytkownik z poprawnymi danymi loguje się przez SSO w ≤ 3 kliknięciach i trafia na dashboard" to misja.
- **`out_of_scope` jest obowiązkowe.** Charter bez granic nie jest charterem — jest niekończącą się sesją.
- **`test_ideas` to pomysły, nie kroki.** Kroki zapisuje tester *w trakcie* sesji (w evidence). Charter podaje kierunki eksploracji, nie scenariusz.
- **`timebox` jest twardy.** Przekroczenie = sesja się kończy, findings się zapisują, nowy charter na resztę.
- **`coverage_type: AUTO`** oznacza, że ścieżka jest pokryta testem automatycznym i charter jest dokumentacją tego pokrycia (MAN-01 spełniony przez auto). **`MANUAL`** oznacza, że ścieżka wymaga człowieka i charter jest aktywną misją.

---

## Część 2 — Format evidence sesji eksploracyjnej (MAN-02/08)

Evidence to **dowód, że sesja się odbyła**, w formacie, który da się audytować i przekuć na testy automatyczne (MAN-06). Bez tego formatu "ktoś kiedyś kliknął" nie jest dowodem.

```yaml
session_id:        <np. SESS-auth-001-20260810>
charter_id:        <odwołanie do charteru — CH-auth-001>
tester:            <kto wykonał — MAN-07: tester ≠ autor>
date:              <YYYY-MM-DD>
environment:
  version:         <wersja artefaktu>
  artifact_digest: <digest artefaktu — MAN-03: evidence bound do digesta>
  environment:     <np. staging | prod | local>
steps_taken:       <co FAKTYCZNIE zrobiono — chronologicznie, z danymi>
findings:          <lista — każdy finding ma strukturę poniżej>
result:            PASS | FAIL | FINDINGS
artifact_digest:   <digest artefaktu, na którym testowano — MAN-03>
evidence_ref:      <link do artefaktu: screenshot, log, video>
converted_test_id: <MAN-06: jeśli finding przekuty na test auto — ID testu>
signoff:           <kto, kiedy, na jaki digest — MAN-03>
```

### Struktura pojedynczego findinga

```yaml
- finding_id:      <np. F-auth-001-01>
  severity:        CRITICAL | HIGH | MEDIUM | LOW | INFO
  description:     <co się stało — zwięźle, konkretnie>
  steps_to_reproduce: <kroki reprodukcji — ktoś inny musi móc powtórzyć>
  expected:        <co miało się stać>
  actual:          <co się faktycznie stało>
  evidence_ref:    <link do artefaktu tego findinga>
```

### Reguły jakości evidence (MAN-08)

- **`steps_taken` to fakty, nie intencje.** "Kliknąłem 'Zaloguj', wpisałem dane testowe, dostałem błąd 500" — nie "sprawdzałem logowania".
- **Każdy finding ma `expected` i `actual`.** Bez pary oczekiwane/faktyczne finding nie jest findingiem — jest wrażeniem.
- **`steps_to_reproduce` musi być powtarzalny.** Test: czy inna osoba, czytając tylko kroki, odtworzy problem?
- **`result: FINDINGS`** oznacza: sesja się odbyła, znaleziono problemy, ale nie ma jednoznacznego FAIL całej ścieżki. **`FAIL`** = ścieżka nie działa zgodnie z akceptacją. **`PASS`** = brak findingsów.
- **`converted_test_id`** to serce MAN-06: każdy finding, który da się zautomatyzować, *powinien* zostać przekuty na test automatyczny. Puste pole = finding czeka na konwersję.

---

## Część 3 — Template UAT sign-off (MAN-03)

Sign-off to **akceptacja związana z konkretnym digestem artefaktu**. Podpisujesz to, co faktycznie widziałeś — nie "wersję ogólnie". To czyni akceptację niepodrabialną: nie da się podpisać na artefakt, którego nie testowano.

```yaml
signoff_id:        <np. SO-auth-001-20260810>
service_id:        <id serwisu — auth-service>
artifact_digest:   <digest artefaktu — DOKŁADNIE ten, na którym testowano>
tier:              <0|1|2>
approver:          <kto akceptuje — MAN-07: nie autor, nie tester>
signed_at:         <YYYY-MM-DD>
evidence_ref:      <link do evidence sesji, która to potwierdza>
statement:         <co DOKŁADNIE akceptuję — na ten konkretny digest>
conditions:        <warunki akceptacji, jeśli są — puste = bezwarunkowo>
```

### Reguły sign-off

- **`artifact_digest` jest obowiązkowy i musi się zgadzać** z digestem w evidence sesji (MAN-03). Rozbieżność = sign-off nieważny.
- **`statement` jest konkretny.** "Akceptuję logowanie przez SSO dla auth-service na digest `sha256:abc…`" — nie "akceptuję auth-service".
- **`approver` ≠ `tester` ≠ `author`** (MAN-07, separation of duties). Brak self-approval.
- **`conditions`** pozwalają na akceptację warunkową (np. "akceptuję, pod warunkiem że finding F-auth-001-01 zostanie naprawiony przed release tier-1").

---

## Część 4 — Przykład (wypełniony)

Kompletny, realistyczny przykład dla ścieżki **"Rejestracja nowego użytkownika"** w serwisie `auth-service` (tier 1). Pokazuje: charter → sesja → finding → konwersja na test → sign-off.

### 4.1 Charter

```yaml
charter_id:        CH-auth-002
service_id:        auth-service
journey_id:        JRN-register
tier:              1
coverage_type:     MANUAL
title:             "Zarejestruj nowego użytkownika"
mission:           "Sprawdź, czy nowy użytkownik z poprawnymi danymi rejestruje się,
                    dostaje e-mail weryfikacyjny i może zalogować się po weryfikacji."
scope:             "Formularz rejestracji, walidacja pól, wysyłka e-maila weryfikacyjnego,
                    potwierdzenie konta, pierwsze logowanie."
out_of_scope:      "Logowanie przez SSO (osobny charter CH-auth-001), reset hasła,
                    integracje z płatnościami, wydajność pod obciążeniem."
preconditions:     "Środowisko staging, SMTP testowy (MailHog), baza z czystym stanem,
                    dostęp do skrzynki testowej, konto admina do czyszczenia danych."
test_ideas:        "Rejestracja z poprawnymi danymi; z zajętym e-mailem; z niepoprawnym
                    formatem e-maila; z krótkim hasłem; puste pola; podwójne kliknięcie
                    'Zarejestruj'; e-mail weryfikacyjny z wygasłym linkiem; rejestracja
                    z polskimi znakami w imieniu."
timebox:           45 min
owner:             "tester-qa"
created_at:        2026-08-10
status:            COMPLETED
acceptance_criteria: "Wszystkie test_ideas sprawdzone, każdy finding ma expected/actual,
                      sesja zakończona z wynikiem PASS lub FINDINGS z planem konwersji."
```

### 4.2 Evidence sesji eksploracyjnej

```yaml
session_id:        SESS-auth-002-20260810
charter_id:        CH-auth-002
tester:            tester-qa
date:              2026-08-10
environment:
  version:         auth-service v1.4.2
  artifact_digest: sha256:9f2c4a1b8e3d7c5f0a6b2e4d8c1f3a5b7d9e0c2a4b6d8f0e1c3a5b7d9e0f2a4c
  environment:     staging
steps_taken:       "1. Otworzyłem /register na staging. 2. Wypełniłem formularz poprawnymi
                    danymi (jan.kowalski@example.com, hasło 'Test!1234'). 3. Kliknąłem
                    'Zarejestruj'. 4. Sprawdziłem MailHog — e-mail weryfikacyjny dotarł.
                    5. Kliknąłem link weryfikacyjny. 6. Zalogowałem się. 7. Powtórzyłem
                    z zajętym e-mailem — dostałem komunikat o błędzie."
findings:
  - finding_id:      F-auth-002-01
    severity:        HIGH
    description:     "Po rejestracji z zajętym e-mailem komunikat błędu jest pusty
                      (biały obszar zamiast tekstu)."
    steps_to_reproduce: "1. Zarejestruj użytkownika jan.kowalski@example.com.
                         2. Spróbuj zarejestrować ponownie ten sam e-mail.
                         3. Obserwuj komunikat pod formularzem."
    expected:        "Komunikat 'Ten adres e-mail jest już zarejestrowany'."
    actual:          "Pusty, biały obszar — brak tekstu komunikatu."
    evidence_ref:    "artifacts/auth-002/finding-01-empty-error.png"
result:            FINDINGS
artifact_digest:   sha256:9f2c4a1b8e3d7c5f0a6b2e4d8c1f3a5b7d9e0c2a4b6d8f0e1c3a5b7d9e0f2a4c
evidence_ref:      "artifacts/auth-002/session-log.txt"
converted_test_id: E2E-auth-register-duplicate-email   # MAN-06: finding przekuty na test auto
signoff:           "pending — czeka na naprawę F-auth-002-01"
```

### 4.3 Finding przekuty na test automatyczny (MAN-06)

Finding `F-auth-002-01` został przekuty na test `E2E-auth-register-duplicate-email`:

```yaml
converted_test_id: E2E-auth-register-duplicate-email
test_type:         e2e
assertion:         "Po rejestracji z zajętym e-mailem widoczny jest komunikat
                    'Ten adres e-mail jest już zarejestrowany' (niepusty)."
status:            OPEN   # czeka na naprawę błędu, potem GREEN
```

To jest pętla MAN-06 w akcji: **finding manualny → test automatyczny → mniej pracy manualnej w przyszłości.** `conversion_rate` rośnie, HUMAN PLANE się kurczy.

### 4.4 UAT sign-off (po naprawie i ponownej weryfikacji)

```yaml
signoff_id:        SO-auth-002-20260812
service_id:        auth-service
artifact_digest:   sha256:7b3d5e9f1a2c4b6d8e0f1a3c5b7d9e0f2a4c6b8d0e1f3a5c7b9d0e2f4a6c8b0d1e3f
tier:              1
approver:          product-owner
signed_at:         2026-08-12
evidence_ref:      "artifacts/auth-002/session-log.txt + artifacts/auth-002/signoff-screenshot.png"
statement:         "Akceptuję rejestrację nowego użytkownika w auth-service na digest
                    sha256:7b3d…e3f (wersja v1.4.3), w tym naprawę findinga F-auth-002-01
                    i przejście testu E2E-auth-register-duplicate-email."
conditions:        "Brak — akceptacja bezwarunkowa na wskazany digest."
```

Zauważ: **digest w sign-off (`7b3d…e3f`) różni się od digesta w pierwszej sesji (`9f2c…a4c`)** — bo akceptacja dotyczy *naprawionej* wersji. To jest sedno MAN-03: podpisujesz dokładnie to, co widziałeś, nie "auth-service ogólnie".

---

## TL;DR — jak używać tego szablonu

```
charter (bounded mission) → sesja (evidence z expected/actual) → finding → [MAN-06: test auto] → sign-off (na digest)
```

1. **Charter** definiuje *co i dlaczego* — bounded, z timeboxem i acceptance criteria.
2. **Sesja** dowodzi *co zrobiono i co znaleziono* — z powtarzalnymi krokami i parą expected/actual.
3. **Finding** jest *przekuwany na test automatyczny* (MAN-06) — system sam się automatyzuje.
4. **Sign-off** jest *związany z digestem artefaktu* (MAN-03) — akceptacja niepodrabialna.

Każdy artefakt bez poprzedniego jest bezwartościowy: charter bez sesji to deklaracja, sesja bez charteru to chaos, sign-off bez digesta to podpis w powietrzu. Ten szablon domyka pętlę: **człowiek jest oracle, proces jest gate'em, a system sam się automatyzuje.**
